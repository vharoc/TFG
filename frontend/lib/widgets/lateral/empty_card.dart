import 'package:flutter/material.dart';

class LateralEmptyCard extends StatelessWidget {
  final String mensaje;

  const LateralEmptyCard({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Center(
        child: Text(
          mensaje,
          style: const TextStyle(fontSize: 13, color: Colors.black38),
        ),
      ),
    );
  }
}
