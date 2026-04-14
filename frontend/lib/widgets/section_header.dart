import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {

  final String header;

  const SectionHeader({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        header.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.black,
        ),
      ),
    );
  }

}