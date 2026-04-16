import 'package:flutter/material.dart';

class HeaderHome extends StatelessWidget {
  
  final String? titulo;

  const HeaderHome({
    super.key,
    this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      // decoration: const BoxDecoration(
      //   color: Color(0xFFFAF7F4),
      //   border: Border(bottom: BorderSide(color: Color(0xFFE0DAD4), width: 1)),
      // ),
      child: Center(
        child: (titulo == null || titulo!.isEmpty) 
          ? const SizedBox.shrink() 
          : Text(
            titulo!,
            style: const TextStyle (
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ),
    );
  }
}
