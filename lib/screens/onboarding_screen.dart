import 'package:flutter/material.dart';
import 'package:intro_screen_onboarding_flutter/introduction.dart';
import 'package:intro_screen_onboarding_flutter/introscreenonboarding.dart';
import 'package:safespace/authentication/welcome.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Introduction> list = [
      Introduction(
        title: 'Welcome to SafeSpace',
        subTitle:
            'A supportive space to care for your mental health with AI guidance.',
        imageUrl: 'assets/images/welcome.png',
        imageHeight: 250,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.tertiary,
        ),
        subTitleTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      Introduction(
        title: 'Your Mental Wellness, All in One Place',
        subTitle:
            'Everything you need to support your mental health journey', // Main subheading

        imageUrl: 'assets/images/welcome.png',
        imageHeight: 250,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.tertiary,
        ),
        subTitleTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Main onboarding content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: IntroScreenOnboarding(
                  introductionList: list,
                  onTapSkipButton: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  },
                  backgroudColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  skipTextStyle: const TextStyle(
                    fontSize: 0, // Hides the built-in skip button
                  ),
                  // Removed unsupported footerBuilder parameter
                ),
              ),
            ),

            // Custom skip text button at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                },
                child: Text(
                  "Skip",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for animated items with delay
class AnimatedItem extends StatefulWidget {
  final Widget child;
  final double delay;

  const AnimatedItem({super.key, required this.child, required this.delay});

  @override
  State<AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<AnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start animation after the delay
    Future.delayed(Duration(seconds: widget.delay.toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
