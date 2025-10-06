import 'package:flutter/material.dart';
import 'package:safespace/navmanager.dart';
import 'package:safespace/authentication/sign_up.dart';
import 'package:safespace/authentication/login_page.dart';
import 'package:safespace/authentication/widgets/welcome_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.network(
            'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/welcomebackground.jpg', // placeholder
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Welcome text section - made more flexible
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 36.0,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ), // Added white color for better visibility
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Enter personal details to your employee account',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(
                                  255,
                                  59,
                                  58,
                                  58,
                                ), // Added white color for better visibility
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Buttons section - made more compact
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        WelcomeButton(
                          buttonText: 'Login',
                          onTap: LoginPage(),
                          color: Colors.blue,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        WelcomeButton(
                          buttonText: 'Sign Up',
                          onTap: const SignUpPage(),
                          color: Colors.green,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        WelcomeButton(
                          buttonText: 'Guest',
                          onTap: NavManager(isGuest: true),
                          color: Colors.grey,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
