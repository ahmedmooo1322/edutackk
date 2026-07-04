import 'package:flutter/material.dart';

class EduTrackLogo extends StatelessWidget {
  const EduTrackLogo({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.menu_book_rounded, color: Colors.white, size: size * 0.47),
          Positioned(
            right: size * 0.18,
            top: size * 0.18,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(size * 0.08),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: const Color(0xFF1E3A8A), size: size * 0.14),
            ),
          ),
        ],
      ),
    );
  }
}
