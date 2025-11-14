import 'package:intl/intl.dart';
import 'package:safespace/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:safespace/screens/chatbot.dart';
import 'package:safespace/screens/notification.dart';
import 'package:safespace/authentication/auth_service.dart';
import 'package:safespace/screens/suggestion_generator_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safespace/services/notification_manager.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, RouteAware {
  final _authService = AuthService();

  // Global key to access RecommendedSuggestionsWidget
  final GlobalKey<RecommendedSuggestionsWidgetState> _suggestionsWidgetKey =
      GlobalKey<RecommendedSuggestionsWidgetState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Custom theme color
  final Color _primaryColor = const Color.fromARGB(255, 74, 146, 128);
  final Color _backgroundColor = const Color(0xFFf8fdfb);
  final Color _onBackgroundColor = const Color(0xFF1a1a1a);
  final Color _onSurfaceColor = const Color(0xFF2d2d2d);

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
    // Set the global refresh callback
    setHomeScreenRefreshCallback(_refreshData);
    print('HomeScreen: Initializing - Guest mode: ${widget.isGuest}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
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
    routeObserver.unsubscribe(this);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the user returns to this screen (e.g., pressing back button)
    print('HomeScreen: User returned to home screen, refreshing data...');
    _refreshData();

    // Show daily reminder if user hasn't viewed recommendations today
    if (!widget.isGuest) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          NotificationManager().showDailyReminder(context, () {
            // Action when user taps the recommendation action
            // (already on home screen, recommendations are visible)
          });
        }
      });
    }
  }

  // Public method to refresh data (can be called from parent)
  void refreshData() {
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      // This will trigger a rebuild and refresh all dynamic content
      print('HomeScreen: Data refreshed');
    });
    // Also refresh the recommendations widget
    _suggestionsWidgetKey.currentState?.refreshSuggestions();
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

  // Get current user ID for authenticated users
  String? get _currentUserId {
    if (widget.isGuest) return null;
    try {
      return _authService.getCurrentUserId();
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
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

                      // Recommendations Section
                      _buildRecommendationsSection(),

                      const SizedBox(height: 16),

                      // Recommendations Widget
                      _buildRecommendationsWidget(),

                      const SizedBox(height: 100), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                vertical: 6.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row (Profile, Date, Notification)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Date (centered)
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
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 10, 10, 10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Notification Button
                      Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            14,
                            13,
                            13,
                          ).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LineIcons.bell,
                            color: Color.fromARGB(255, 7, 7, 7),
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

                  // instead of Spacer() ⛔ use small SizedBox
                  const SizedBox(height: 11),

                  // Greeting Section
                  Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userGreeting,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(
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
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            shadows: [
                              const Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "\"Your mental health is a priority. Take it one day at a time.\"",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              const Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
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
              colors: [
                _primaryColor.withOpacity(0.1),
                _primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/chatbot_app.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _primaryColor,
                        child: Icon(
                          LineIcons.robot,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
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
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isGuest
                          ? "Get personalized mental health support"
                          : "Your AI companion is ready to listen",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: _primaryColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Recommendations",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1a1a1a),
              ),
            ),
            Text(
              widget.isGuest
                  ? "Sign in to see personalized suggestions"
                  : "Based on your recent conversations",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF2d2d2d).withOpacity(0.6),
              ),
            ),
          ],
        ),
        if (widget.isGuest)
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.login, size: 16),
            label: Text('Sign In', style: GoogleFonts.poppins()),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A9280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          )
        else
          Container(), // Empty container for layout consistency
      ],
    );
  }

  Widget _buildRecommendationsWidget() {
    if (widget.isGuest) {
      return _buildGuestRecommendations();
    }

    final userId = _currentUserId;
    if (userId == null) {
      return Container(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: _onSurfaceColor.withOpacity(0.4),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load recommendations',
                style: GoogleFonts.poppins(
                  color: _onSurfaceColor.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RecommendedSuggestionsWidget(
      key: _suggestionsWidgetKey,
      userId: userId,
    );
  }

  Widget _buildGuestRecommendations() {
    return Column(
      children: [
        _buildGuestSuggestionCard(
          icon: Icons.visibility_outlined,
          title: "Limit Exposure to Screens",
          subtitle: "Control your screen time for better mental health",
          iconColor: const Color(0xFF2196F3),
        ),
        const SizedBox(height: 12),
        _buildGuestSuggestionCard(
          icon: Icons.bed,
          title: "Improve Sleep Quality",
          subtitle: "Maintain a consistent sleep schedule",
          iconColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        _buildGuestSuggestionCard(
          icon: Icons.sports_gymnastics,
          title: "Regular Exercise",
          subtitle: "Stay active for mental and physical well-being",
          iconColor: const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildGuestSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return TweenAnimationBuilder(
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFffffff),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
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
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF2d2d2d).withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock,
              size: 16,
              color: const Color(0xFF2d2d2d).withOpacity(0.4),
            ),
          ],
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
      label: Text('Sign In', style: GoogleFonts.poppins()),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
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
                    Icon(Icons.lock_outline, color: _primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Guest Mode Restriction',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: _onBackgroundColor,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Please sign in to access all features and personalized content.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _onSurfaceColor,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Later',
                      style: GoogleFonts.poppins(color: _primaryColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Sign In Now', style: GoogleFonts.poppins()),
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
