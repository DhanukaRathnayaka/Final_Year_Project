import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NotificationManager handles onboarding, chatbot, and daily reminders.
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  static const String _onboardingKey = 'onboarding_notification_shown';
  static const String _chatbotKey = 'chatbot_notification_shown';
  static const String _lastDailyReminderKey = 'last_daily_reminder';

  // Theme colors matching the app
  static const Color _primaryColor = Color(0xFF4A9280);
  static const Color _accentGreen = Color(0xFF6ABFA0);
  static const Color _lightBg = Color(0xFFEAFBF5);

  /// Show onboarding notification for new users after sign-up
  Future<void> showOnboardingNotification(
    BuildContext context,
    VoidCallback onChatbot,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_onboardingKey) ?? false;
    if (!shown) {
      _showBeautifulNotification(
        context,
        icon: Icons.chat_bubble_outline,
        title: 'Welcome to SafeSpace!',
        message:
            'Start with a quick chat to understand how you\'re feeling today.',
        actionLabel: 'Start Chat',
        onAction: onChatbot,
        isPrimary: true,
      );
      await prefs.setBool(_onboardingKey, true);
    }
  }

  /// Show notification after chatbot conversation ends
  Future<void> showChatbotEndNotification(
    BuildContext context,
    VoidCallback onRecommendations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_chatbotKey) ?? false;
    if (!shown) {
      _showBeautifulNotification(
        context,
        icon: Icons.lightbulb_outline,
        title: 'Great Progress!',
        message:
            'Based on your chat, we have new recommendations for you — Entertainment, Doctors, and CBT exercises.',
        actionLabel: 'View Recommendations',
        onAction: onRecommendations,
        isPrimary: true,
      );
      await prefs.setBool(_chatbotKey, true);
    }
  }

  /// Show daily reminder if recommendations haven't been viewed
  Future<void> showDailyReminder(
    BuildContext context,
    VoidCallback onRecommendations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_lastDailyReminderKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (lastShown != todayStr) {
      _showBeautifulNotification(
        context,
        icon: Icons.favorite_outline,
        title: 'Your Activities Await',
        message:
            'Your personalized activities are ready. Check your recommended Entertainment, Doctor options, and CBT exercises.',
        actionLabel: 'View Recommendations',
        onAction: onRecommendations,
        isPrimary: false,
      );
      await prefs.setString(_lastDailyReminderKey, todayStr);
    }
  }

  /// Beautiful custom notification widget with theme colors
  void _showBeautifulNotification(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool isPrimary = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPrimary
                  ? [_primaryColor.withOpacity(0.1), _lightBg.withOpacity(0.3)]
                  : [
                      Color(0xFFFFF9E6).withOpacity(0.5),
                      Color(0xFFFFE680).withOpacity(0.2),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? _accentGreen.withOpacity(0.4)
                  : Colors.amber.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isPrimary ? _primaryColor : Colors.amber).withOpacity(
                    0.2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? _primaryColor : Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPrimary ? _primaryColor : Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2d2d2d).withOpacity(0.8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isPrimary ? _primaryColor : Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        onAction();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// For testing: reset all notification flags
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
    await prefs.remove(_chatbotKey);
    await prefs.remove(_lastDailyReminderKey);
  }
}
