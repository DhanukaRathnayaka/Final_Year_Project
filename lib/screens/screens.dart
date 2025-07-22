import 'profile.dart';
import 'counsellor.dart';
import 'entertainment.dart';
import 'package:flutter/material.dart';
import 'package:safespace/homescreen.dart';


// lib/screens/screens.dart

List<Widget> screensWithTheme() => [
  HomeScreen(),
  EntertainmentScreen(),
  CounsellorScreen(),
  ProfileScreen(),
];
