import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 60, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE50914), Color(0xFFB71C1C)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE50914).withAlpha(80),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.movie_creation_rounded,
              color: Colors.white,
              size: size * 0.55,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'CinemaFlix',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE50914),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: size * 0.06),
          Text(
            'Your Movie World',
            style: TextStyle(
              fontSize: size * 0.16,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
