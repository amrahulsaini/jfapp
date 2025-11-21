import 'package:flutter/material.dart';
import '../config/theme.dart';

class JFLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const JFLogo({
    super.key,
    this.size = 80,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // JF Logo
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
          child: Stack(
            children: [
              // Orange accent corner
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(size * 0.2),
                    ),
                  ),
                ),
              ),
              // JF Text
              Center(
                child: Text(
                  'JF',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.secondaryColor,
                    letterSpacing: -2,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'JECRC Foundation',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
