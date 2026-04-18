import 'package:flutter/material.dart';

class HeaderHome extends StatelessWidget {
  final String? titulo;

  const HeaderHome({super.key, this.titulo});

  @override
  Widget build(BuildContext context) {
    final bool tieneTitulo = titulo != null && titulo!.isNotEmpty;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEAE4), width: 1),
        ),
      ),
      child: Center(
        child: tieneTitulo
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64),
                child: Text(
                  titulo!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}