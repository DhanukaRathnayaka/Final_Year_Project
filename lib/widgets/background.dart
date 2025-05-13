import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

class TimeBasedBackground extends StatefulWidget {
  final Widget child;

  const TimeBasedBackground({Key? key, required this.child}) : super(key: key);

  @override
  _TimeBasedBackgroundState createState() => _TimeBasedBackgroundState();
}

class _TimeBasedBackgroundState extends State<TimeBasedBackground> {
  late bool _isDayTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isDayTime = _checkIsDayTime();

    // Check every minute for time change
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final isDay = now.hour >= 6 && now.hour < 18;

      if (isDay != _isDayTime) {
        setState(() {
          _isDayTime = isDay;
        });
      }
    });
  }

  bool _checkIsDayTime() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = _isDayTime ? 'assets/images/day_bg.jpg' : 'assets/images/night_bg.jpg';

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgImage),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: widget.child,
        ),
      ),
    );
  }
}
