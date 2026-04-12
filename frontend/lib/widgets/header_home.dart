import 'package:flutter/material.dart';

class HeaderHome extends StatelessWidget {

  const HeaderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F4),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0DAD4), width: 1),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }

}