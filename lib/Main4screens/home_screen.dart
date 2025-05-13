import 'package:flutter/material.dart';
import 'package:safespace/Main4screens/doctor.dart';
import 'package:safespace/Main4screens/profile.dart';
import 'package:safespace/Navigationbar/navbar.dart';
import 'package:safespace/Main4screens/entertainment.dart';
import 'package:safespace/Main4screens/dashboard_screen.dart';
// home_screen.dart

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(),
      const Entertainment(),
      CounsellorsApp(),
      ProfilePage(),
    ];
  }

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}
