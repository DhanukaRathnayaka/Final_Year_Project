import 'navbar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Page $_selectedIndex')), 
      bottomNavigationBar: NavBar(
        onTabChange: _onTabChange,
        selectedIndex: _selectedIndex,
      ),
    );
  }
}
