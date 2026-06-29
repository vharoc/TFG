import 'package:flutter/material.dart';

class HamburgerButton extends StatelessWidget {
  final VoidCallback? onTap;

  const HamburgerButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linea(20),
                const SizedBox(height: 5),
                _linea(13),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _linea(double width) => Container(
        width: width,
        height: 2,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}