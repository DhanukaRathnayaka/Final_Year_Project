import 'package:flutter/material.dart';
import 'package:safespace/screens/doctor.dart';
import 'package:safespace/screens/profile.dart';
import 'package:safespace/screens/entertainment.dart';
import 'package:safespace/widgets/navbar.dart'; // Import NavBar widget
import 'package:safespace/screens/dashboard_screen.dart'; // Import DashboardScreen


class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({Key? key, required this.username}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Initial tab index

  final List<Widget> _pages = [
    DashboardScreen(),
    const Entertainment(),
    CounsellorsApp(),
    ProfilePage(),
  ];

  // Method to handle tab changes
  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index when a tab is clicked
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex], // Show selected page
      bottomNavigationBar: NavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}
