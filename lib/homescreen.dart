import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:safespace/screens/chatbot.dart';
import 'package:safespace/screens/notification.dart';
import 'package:safespace/authentication/auth_service.dart';
import 'package:safespace/services/suggestion_service.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _authService = AuthService();
  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Background image selection with alignment based on time of day
  String get _backgroundImage {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6
        ? 'assets/images/night_bg.jpg'
        : 'assets/images/day_bg.jpg';
  }

  String get _formattedDate {
    return DateFormat('dd MMM yyyy').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (!widget.isGuest) {
      print('HomeScreen: Initializing for authenticated user');
      _fetchAISuggestions();
    } else {
      print('HomeScreen: Initializing for guest user');
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String get _userGreeting {
    if (widget.isGuest) return "Hello Guest";

    try {
      // First try to get the username from user metadata
      final metadata = _authService.getCurrentUserMetadata();
      final username = metadata?['username'] as String?;

      if (username != null && username.isNotEmpty) {
        return "Hello $username";
      }

      // Fallback to email if username not available
      final email = _authService.getCurrentUserEmail();
      if (email != null) {
        final name = email.split('@').first;
        return "Hello $name";
      }

      return "Hello User";
    } catch (e) {
      // Handle any potential errors gracefully
      debugPrint('Error getting user greeting: $e');
      return "Hello User";
    }
  }

  Future<void> _fetchAISuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final suggestionService = SuggestionService();
      final suggestions = await suggestionService.getSuggestions();
      print('Fetched suggestions: $suggestions'); // Debug log

      // Process the suggestions to match the expected format
      List<dynamic> processedSuggestions = [];

      // Add doctor suggestions
      if (suggestions['doctors'] != null && suggestions['doctors'].isNotEmpty) {
        for (var doctor in suggestions['doctors']) {
          processedSuggestions.add({
            'title': 'Doctor Recommendation',
            'description':
                'We recommend consulting with ${doctor['name']} who specializes in ${doctor['dominant_state'] ?? 'general mental health'}',
            'type': 'doctor',
            'data': doctor,
          });
        }
      }

      // Add entertainment suggestions
      if (suggestions['entertainments'] != null &&
          suggestions['entertainments'].isNotEmpty) {
        for (var entertainment in suggestions['entertainments']) {
          processedSuggestions.add({
            'title': entertainment['title'] ?? 'Entertainment',
            'description': entertainment['type'] ?? 'Entertainment suggestion',
            'type': 'entertainment',
            'data': entertainment,
          });
        }
      }

      print('Processed suggestions: $processedSuggestions'); // Debug log
      setState(() {
        _suggestions = processedSuggestions;
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      print('Error fetching AI suggestions: $e');
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: widget.isGuest ? () async {} : _fetchAISuggestions,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Dynamic Background
              _buildHeaderSection(),
              // small spacer so the header bg doesn't overlap the next card
              Container(height: 12),

              // Main Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Chat Card
                        _buildChatCard(),

                        const SizedBox(height: 24),

                        // Suggestions Section
                        _buildSuggestionsSection(),

                        const SizedBox(height: 16),

                        // Suggestion Cards
                        _buildSuggestionCards(),

                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isGuest ? _buildGuestFAB() : null,
    );
  }

  Widget _buildHeaderSection() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            _backgroundImage,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // Gradient overlay for contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Foreground content (profile row + greetings)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row (Profile, Date, Notification)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: widget.isGuest
                              ? const AssetImage('assets/images/guest.png')
                              : const AssetImage('assets/images/profile.jpg'),
                          child: widget.isGuest
                              ? Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                )
                              : null,
                        ),
                      ),

                      // Date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Notification Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LineIcons.bell,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: widget.isGuest
                              ? () => _showGuestRestriction(context)
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsPage(),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Greeting Section (kept content exactly as before)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userGreeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isGuest
                              ? "Enjoy limited access as guest"
                              : "We hope you are doing great today",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "Thought of the day",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard() {
    return GestureDetector(
      onTap: widget.isGuest
          ? () => _showGuestRestriction(context)
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatBotScreen()),
              );
            },
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LineIcons.robot, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isGuest
                          ? "Sign in to access chatbot"
                          : "Hello! Let's Chat",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isGuest
                          ? "Get personalized mental health support"
                          : "Your AI companion is ready to listen",
                      style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.blue[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Suggestions",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              "Personalized recommendations for you",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        if (widget.isGuest)
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Sign In'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          )
        else
          IconButton(
            onPressed: _isLoadingSuggestions ? null : _fetchAISuggestions,
            icon: _isLoadingSuggestions
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[600]!,
                      ),
                    ),
                  )
                : Icon(Icons.refresh, color: Colors.blue[600]),
            tooltip: 'Refresh suggestions',
          ),
      ],
    );
  }

  Widget _buildSuggestionCards() {
    if (_isLoadingSuggestions) {
      return Container(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading suggestions...',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_suggestions.isNotEmpty) {
      return Column(
        children: _suggestions.map((suggestion) {
          return _buildSuggestionCard(
            icon: suggestion['type'] == 'doctor'
                ? Icons.medical_services
                : Icons.movie,
            title: suggestion['title'] ?? 'Suggestion',
            subtitle:
                suggestion['description'] ??
                'Personalized suggestion based on your conversation',
            iconColor: suggestion['type'] == 'doctor'
                ? Colors.red[600]!
                : Colors.purple[600]!,
            isLocked: widget.isGuest,
            onTap: widget.isGuest
                ? null
                : () => _handleSuggestionTap(suggestion),
          );
        }).toList(),
      );
    }

    // Default suggestions if no AI suggestions
    return Column(
      children: [
        _buildSuggestionCard(
          icon: Icons.visibility_outlined,
          title: "Limit Exposure to Screens",
          subtitle: "Control your screen time for better mental health",
          iconColor: Colors.green[600]!,
          isLocked: widget.isGuest,
        ),
        _buildSuggestionCard(
          icon: Icons.bed,
          title: "Improve Sleep Quality",
          subtitle: "Maintain a consistent sleep schedule",
          iconColor: Colors.orange[600]!,
          isLocked: widget.isGuest,
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline : icon,
                    color: isLocked ? Colors.grey[400] : iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey[400] : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocked ? "Sign in to view details" : subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isLocked ? Colors.grey[400] : Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock : Icons.arrow_forward_ios,
                  size: 16,
                  color: isLocked ? Colors.grey[400] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      icon: const Icon(Icons.login),
      label: const Text('Sign In'),
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _handleSuggestionTap(Map<String, dynamic> suggestion) {
    if (suggestion['type'] == 'doctor') {
      // Navigate to doctor screen or show doctor details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Doctor: ${suggestion['data']['name']}')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (suggestion['type'] == 'entertainment') {
      // Navigate to entertainment screen or show entertainment details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.movie, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Entertainment: ${suggestion['title']}')),
            ],
          ),
          backgroundColor: Colors.purple[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showGuestRestriction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text(
                      'Guest Mode Restriction',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  'Please sign in to access all features and personalized content.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Later'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Sign In Now'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
