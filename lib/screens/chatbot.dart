import 'dart:async';
import 'dart:convert';
import 'package:safespace/main.dart';
import 'package:flutter/material.dart';
import 'package:safespace/config.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
import 'package:safespace/services/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/services/mental_state_service.dart';

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
  String? userAvatarUrl;
  String? currentConversationId;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  String selectedModel = "llama2-70b-4096";

  // Add MentalStateService instance
  final MentalStateService _mentalStateService = MentalStateService();
  bool _analysisTriggered = false;
  bool _suggestionsTriggered = false;

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

    // Fetch user metadata to get avatar URL
    final metadata = user?.userMetadata;
    final avatarUrl = metadata?['avatar_url'] as String?;

    setState(() {
      userId = user?.id;
      userAvatarUrl = avatarUrl;
    });
  }

  Future<void> _startNewConversation() async {
    setState(() {
      messages = [];
      isLoading = true;
      _analysisTriggered = false; // Reset analysis trigger for new conversation
      _suggestionsTriggered =
          false; // Reset suggestions trigger for new conversation
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

  // Simplified method without SuggestionGeneratorWidget
  Future<void> _generateAndShowSuggestions() async {
    if (userId == null || currentConversationId == null || messages.isEmpty) {
      return;
    }

    try {
      // Make HTTP request to AI suggestions endpoint
      final url = Uri.parse(
        '${Config.apiBaseUrl}/ai-suggestions/suggestions/$userId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Trigger homescreen refresh
          triggerHomeScreenRefresh();
          print('AI suggestions generated for user: $userId');
        } else {
          // Show error message from API
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to generate suggestions: ${data['message'] ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Handle HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to connect to AI service. Please try again later.',
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error generating AI suggestions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error generating suggestions. Please check your connection.',
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
        ),
      );
    }
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
          title: const Text('?End Conversation'),
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

  // Add this method to trigger AI suggestions after mental state analysis
  Future<void> _triggerAISuggestions() async {
    if (_suggestionsTriggered) return;

    setState(() {
      _suggestionsTriggered = true;
    });

    await _generateAndShowSuggestions();
  }

  // Add this method to check and trigger mental state analysis
  Future<void> _checkAndTriggerMentalStateAnalysis() async {
    if (userId == null || _analysisTriggered) return;

    final hasEnoughMessages = await _mentalStateService.hasEnoughMessages(
      userId!,
    );

    if (hasEnoughMessages) {
      setState(() {
        _analysisTriggered = true;
      });

      // Run analysis in background
      _mentalStateService
          .analyzeUserMentalState(userId!)
          .then((_) {
            print('Mental state analysis completed for user: $userId');
            // Trigger AI suggestions after analysis
            _triggerAISuggestions();
          })
          .catchError((e) {
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
        backgroundColor: const Color(0xFFf8fdfb),
        appBar: AppBar(
          backgroundColor: const Color(0xFFffffff),
          elevation: 0.5,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/chatbot_app.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        LineIcons.robot,
                        color: Color(0xFF4A9280),
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Wellness Companion',
                      style: TextStyle(
                        color: Color(0xFF1a1a1a),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Let\'s chat at your pace',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2d2d2d).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF4A9280)),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9280).withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF4A9280).withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: const Icon(
              LineIcons.robot,
              size: 56,
              color: Color(0xFF4A9280),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Preparing your space...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1a1a1a),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9280)),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isBot) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4A9280).withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/chatbot_app.png',
                    fit: BoxFit.cover,
                    cacheHeight: 100,
                    cacheWidth: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9280).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          LineIcons.robot,
                          color: Color(0xFF4A9280),
                          size: 22,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot
                    ? const Color(0xFFffffff)
                    : const Color(0xFF4A9280),
                borderRadius: BorderRadius.circular(20),
                border: isBot
                    ? Border.all(
                        color: const Color(0xFF4A9280).withOpacity(0.15),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                        p: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2d2d2d),
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a1a),
                        ),
                      ),
                    )
                  else
                    Text(
                      message['message'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFffffff),
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(message['timestamp']),
                    style: TextStyle(
                      fontSize: 11,
                      color: isBot
                          ? const Color(0xFF4A9280).withOpacity(0.6)
                          : const Color(0xFFffffff).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4A9280).withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: userAvatarUrl != null
                      ? Image.network(
                          userAvatarUrl!,
                          fit: BoxFit.cover,
                          cacheHeight: 100,
                          cacheWidth: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4A9280,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF4A9280),
                                size: 22,
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A9280).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF4A9280),
                            size: 22,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4A9280).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/chatbot_app.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9280).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LineIcons.robot,
                      color: Color(0xFF4A9280),
                      size: 18,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFffffff),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4A9280).withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFF4A9280).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: _typingAnimation.value > index * 0.3
                                ? Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4A9280),
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
                const SizedBox(width: 8),
                const Text(
                  'Companion is responding...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A9280),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFffffff),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFf5f5f5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF4A9280).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF2d2d2d).withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(
                    color: Color(0xFF1a1a1a),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: isLoading
                    ? const Color(0xFF4A9280).withOpacity(0.5)
                    : const Color(0xFF4A9280),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFffffff),
                          ),
                        ),
                      )
                    : const Icon(Icons.send, color: Color(0xFFffffff)),
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
