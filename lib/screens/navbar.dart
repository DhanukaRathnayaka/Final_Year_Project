import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class NavBar extends StatefulWidget {
  final Function(int) onTabChange;
  final int selectedIndex;

  const NavBar({Key? key, required this.onTabChange, required this.selectedIndex}) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(.1), // shadow colour
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: Colors.grey[300]!,// button outside colour change
            hoverColor: Colors.grey[100]!, // button outside colour change
            gap: 8,
            activeColor: Colors.black, // button inside colour change
            iconSize: 24,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: Duration(milliseconds: 400),
            tabBackgroundColor: Colors.blue[100]!, // button inside colour change
            color: Colors.black, // button outside colour change
            tabs: [
              GButton(
                icon: LineIcons.home,
                text: 'Home', //Home 
              ),
              GButton(
                icon: LineIcons.music,
                text: 'Songs', //Songs
              ),
              GButton(
                icon: LineIcons.search,
                text: 'Search',
              ),
              GButton(
                icon: LineIcons.user,
                text: 'Profile',
              ),
            ],
            selectedIndex: widget.selectedIndex,
            onTabChange: widget.onTabChange,
          ),
        ),
      ),
    );
  }
}