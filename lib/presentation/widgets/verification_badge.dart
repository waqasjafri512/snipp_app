import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final double size;
  final Color color;
  final EdgeInsets padding;

  const VerificationBadge({
    super.key, 
    this.size = 14, 
    this.color = Colors.blue,
    this.padding = const EdgeInsets.only(left: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Icon(
        Icons.verified_rounded, 
        color: color, 
        size: size,
      ),
    );
  }
}
