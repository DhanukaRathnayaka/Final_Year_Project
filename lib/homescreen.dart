import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:safespace/screens/chatbot.dart';
import 'package:safespace/screens/notification.dart';
import 'package:safespace/authentication/auth_service.dart';


class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  String get _backgroundImage {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6
        ? 'assets/images/night_bg.jpg'
        : 'assets/images/day_bg.jpg';
  }

  String get _formattedDate {
    return DateFormat('dd MMM yyyy').format(DateTime.now());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Dynamic Background
            Container(
              height: 220,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Top Row (Profile, Date, Notification)
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: widget.isGuest
                              ? const AssetImage('assets/images/guest.png')
                              : const AssetImage('assets/images/profile.jpg'),
                        ),
                        Text(
                          _formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LineIcons.bell, color: Colors.white),
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
                      ],
                    ),
                  ),

                  // Greeting Text
                  Positioned(
                    bottom: 20,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userGreeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isGuest
                              ? "Enjoy limited access as guest"
                              : "We hope you are doing great today",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Thought of the day",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chat Card
            GestureDetector(
              onTap: widget.isGuest
                  ? () => _showGuestRestriction(context)
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatBotScreen(),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.isGuest
                        ? "Sign in to access chatbot"
                        : "Hello! Let's Chat",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            // Suggestions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "AI Suggestions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isGuest)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Sign In'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Suggestion Cards
            _buildSuggestionCard(
              icon: Icons.visibility_outlined,
              title: "Limit Exposure to Screens",
              subtitle: "Control your screen time",
              iconColor: Colors.green,
              isLocked: widget.isGuest,
            ),
            _buildSuggestionCard(
              icon: Icons.bed,
              title: "Pillow Improvement",
              subtitle: "Change your pillows",
              iconColor: Colors.orange,
              isLocked: widget.isGuest,
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isGuest
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    bool isLocked = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocked ? Icons.lock_outline : icon,
                color: isLocked ? Colors.grey : iconColor,
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
                      color: isLocked ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLocked ? "Sign in to view details" : subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isLocked ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isLocked ? Icons.lock : Icons.arrow_forward_ios,
              size: 16,
              color: isLocked ? Colors.grey : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestRestriction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Mode Restriction'),
        content: const Text(
            'Please sign in to access all features and personalized content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Sign In Now'),
          ),
        ],
      ),
    );
  }
}