import 'package:flutter/material.dart';
import 'package:safespace/config.dart';
import 'package:safespace/navmanager.dart';
import 'package:safespace/screens/chatbot.dart';
import 'package:safespace/authentication/sign_up.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/authentication/auth_gate.dart';
import 'package:safespace/authentication/login_page.dart';
import 'package:safespace/services/mental_state_service.dart';

// Custom theme color passe maru krmuuuuuuuuuuuuuuuuuuuuu
const Color primaryColor = Color(0xFF5CCCB4);

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  final swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

final MaterialColor primarySwatch = createMaterialColor(const Color.fromARGB(255, 110, 223, 200));

// service locators
MentalStateService mentalStateService = MentalStateService();

// Global RouteObserver for navigation tracking
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

// Global callback for refreshing homescreen
typedef HomeScreenRefreshCallback = void Function();
HomeScreenRefreshCallback? _homeScreenRefreshCallback;

void setHomeScreenRefreshCallback(HomeScreenRefreshCallback callback) {
  _homeScreenRefreshCallback = callback;
}

void triggerHomeScreenRefresh() {
  _homeScreenRefreshCallback?.call();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSpac',
      theme: ThemeData(primarySwatch: primarySwatch),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const NavManager(isGuest: false),
        '/guest': (context) => const NavManager(isGuest: true),
        '/chatbot': (context) => ChatBotScreen(),
      },
    );
  }
}