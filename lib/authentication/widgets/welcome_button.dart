import 'package:flutter/material.dart';

class WelcomeButton extends StatefulWidget {
  const WelcomeButton({
    super.key,
    required this.buttonText,
    required this.onTap,
    this.color,
    this.textColor,
    this.hoverColor,
    this.elevation = 2.0,
    this.hoverElevation = 6.0,
  });
  
  final String buttonText;
  final Widget onTap;
  final Color? color;
  final Color? textColor;
  final Color? hoverColor;
  final double elevation;
  final double hoverElevation;

  @override
  State<WelcomeButton> createState() => _WelcomeButtonState();
}

class _WelcomeButtonState extends State<WelcomeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.1),
              blurRadius: _isHovered ? 12.0 : 6.0,
              spreadRadius: _isHovered ? 1.0 : 0.5,
              offset: Offset(0, _isHovered ? 4.0 : 2.0),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (e) => widget.onTap),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color ?? Theme.of(context).primaryColor,
            foregroundColor: widget.textColor ?? Colors.white,
            padding: const EdgeInsets.all(18.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: _isHovered ? widget.hoverElevation : widget.elevation,
            shadowColor: Colors.transparent,
            animationDuration: const Duration(milliseconds: 200),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: _isHovered ? 1.02 : 1.0,
            child: Text(
              widget.buttonText,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}