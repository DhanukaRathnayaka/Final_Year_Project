import 'dart:async';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:safespace/services/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/services/mental_state_service.dart';
import 'package:safespace/screens/suggestion_generator_widget.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  bool isTyping = false;
  final supabase = Supabase.instance.client;
  String? userId;
  String? currentConversationId;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  String selectedModel = "llama2-70b-4096";

  // Add MentalStateService instance
  final MentalStateService _mentalStateService = MentalStateService();
  bool _analysisTriggered = false;

  // Animation controllers
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeUser();
    _startNewConversation();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    // Don't end conversation on dispose, let back button handle it
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final user = supabase.auth.currentUser;
    setState(() {
      userId = user?.id;
    });
  }

  Future<void> _startNewConversation() async {
    setState(() {
      messages = [];
      isLoading = true;
      _analysisTriggered = false; // Reset analysis trigger for new conversation
    });

    try {
      // Create a new conversation
      final response = await supabase
          .from('conversations')
          .insert({'user_id': userId})
          .select()
          .single();

      setState(() {
        currentConversationId = response['id'] as String;
      });

      _setupRealtime();
    } catch (e) {
      print('Error starting new conversation: $e');
      _showErrorSnackBar('Failed to start conversation. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _endCurrentConversation() async {
    if (currentConversationId == null) {
      return true; // Allow back navigation if no conversation
    }

    try {
      setState(() {
        isLoading = true;
      });

      // End the conversation in the database
      await supabase
          .from('conversations')
          .update({'ended_at': DateTime.now().toIso8601String()})
          .eq('id', currentConversationId!);

      // Generate AI suggestions based on the conversation if there are messages
      if (messages.isNotEmpty) {
        await _generateAndShowSuggestions();
      }

      return true; // Allow back navigation
    } catch (e) {
      _showErrorSnackBar('Failed to end conversation: ${e.toString()}');
      print('Error ending conversation: $e');
      return false; // Prevent back navigation on error
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Updated method to use the new widget
  Future<void> _generateAndShowSuggestions() async {
    if (userId == null || currentConversationId == null || messages.isEmpty) {
      return;
    }

    final conversationMessages = messages
        .map((msg) => msg['message'] as String)
        .toList();

    // Use the SuggestionGeneratorWidget
    final suggestionGenerator = SuggestionGeneratorWidget(
      conversationMessages: conversationMessages,
      userId: userId!,
      conversationId: currentConversationId!,
    );

    await suggestionGenerator.generateAndShowSuggestions(context);
  }

  // Add this method to handle back button press
  Future<bool> _onWillPop() async {
    if (isLoading) {
      // Prevent back navigation while loading
      return false;
    }

    // Show confirmation dialog if there are messages
    if (messages.isNotEmpty) {
      final shouldEnd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Conversation?'),
          content: const Text(
            'Would you like to end this conversation and get personalized suggestions?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End Conversation'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ),
      );

      if (shouldEnd == true) {
        return await _endCurrentConversation();
      } else {
        return false; // Stay on current screen
      }
    } else {
      // No messages, just end conversation without suggestions
      return await _endCurrentConversation();
    }
  }

  // Add this method to check and trigger mental state analysis
  Future<void> _checkAndTriggerMentalStateAnalysis() async {
    if (userId == null || _analysisTriggered) return;

    final hasEnoughMessages = await _mentalStateService.hasEnoughMessages(userId!);
    
    if (hasEnoughMessages) {
      setState(() {
        _analysisTriggered = true;
      });
      
      // Run analysis in background
      _mentalStateService.analyzeUserMentalState(userId!).then((_) {
        print('Mental state analysis completed for user: $userId');
      }).catchError((e) {
        print('Error in mental state analysis: $e');
      });
    }
  }

  Future<void> _storeMessage(String message, bool isBot) async {
    if (userId == null || currentConversationId == null) return;

    try {
      await supabase.from('messages').insert({
        'conversation_id': currentConversationId,
        'user_id': userId,
        'message': message,
        'is_bot': isBot,
      });

      // Update conversation title with first message
      if (messages.isEmpty && !isBot) {
        await supabase
            .from('conversations')
            .update({'title': _generateConversationTitle(message)})
            .eq('id', currentConversationId!);
      }

      // Check if we should trigger mental state analysis after storing a message
      if (!isBot) {
        _checkAndTriggerMentalStateAnalysis();
      }
    } catch (e) {
      print('Error storing message: $e');
    }
  }

  String _generateConversationTitle(String firstMessage) {
    if (firstMessage.length <= 30) return firstMessage;
    return '${firstMessage.substring(0, 30)}...';
  }

  void _setupRealtime() {
    if (currentConversationId == null) return;

    _messageSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', currentConversationId!)
        .order('created_at')
        .listen((List<Map<String, dynamic>> data) {
          setState(() {
            messages = data
                .map(
                  (msg) => {
                    'message': msg['message'],
                    'is_bot': msg['is_bot'],
                    'timestamp': msg['created_at'],
                  },
                )
                .toList();
          });
          _scrollToBottom();
        });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || isLoading) return;

    setState(() {
      isLoading = true;
      isTyping = true;
    });

    _controller.clear();

    // Add user message to UI immediately
    final userMessage = {
      'message': message,
      'is_bot': false,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      messages.add(userMessage);
    });

    _scrollToBottom();

    try {
      // Store user message
      await _storeMessage(message, false);

      // Start typing animation
      _typingAnimationController.repeat();

      // Send to AI service with user_id
      final response = await ChatService.sendMessage(
        message,
        selectedModel,
        userId: userId, // Pass the user_id
      );

      // Stop typing animation
      _typingAnimationController.stop();

      if (response.startsWith('⚠')) {
        // Handle error response
        _showErrorSnackBar(response.substring(2)); // Remove warning emoji
      } else {
        // Add bot message to UI immediately
        final botMessage = {
          'message': response,
          'is_bot': true,
          'timestamp': DateTime.now().toIso8601String(),
        };

        setState(() {
          messages.add(botMessage);
        });

        _scrollToBottom();

        // Store bot response in background
        await _storeMessage(response, true);

        // Check if this is a goodbye message to trigger recommendations
        final lowerResponse = response.toLowerCase();
        if (lowerResponse.contains('goodbye') ||
            lowerResponse.contains('bye') ||
            lowerResponse.contains('take care')) {
          // Show a loading message for recommendations
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Preparing your personalized recommendations...',
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.blue[600],
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      _showErrorSnackBar(
        'Connection error. Please check your internet connection.',
      );
    } finally {
      setState(() {
        isLoading = false;
        isTyping = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LineIcons.robot, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI Companion',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Always here to listen',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue[600]),
              onPressed: isLoading ? null : _startNewConversation,
              tooltip: 'New conversation',
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages area
            Expanded(
              child: isLoading && messages.isEmpty
                  ? _buildLoadingState()
                  : _buildMessagesList(),
            ),

            // Typing indicator
            if (isTyping) _buildTypingIndicator(),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(LineIcons.robot, size: 48, color: Colors.blue[600]),
          ),
          SizedBox(height: 16),
          Text(
            'Starting conversation...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message, index);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, int index) {
    final isBot = message['is_bot'] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LineIcons.robot, color: Colors.blue[700], size: 20),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : Colors.blue[600],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBot)
                    MarkdownBody(
                      data: message['message'] ?? '',
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                    )
                  else
                    Text(
                      message['message'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message['timestamp']),
                    style: TextStyle(
                      fontSize: 11,
                      color: isBot ? Colors.grey[500] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isBot) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LineIcons.robot, color: Colors.blue[700], size: 20),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                            child: _typingAnimation.value > index * 0.3
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue[600],
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  'AI is typing...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey[400] : Colors.blue[600],
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.send, color: Colors.white),
                onPressed: isLoading ? null : _sendMessage,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}