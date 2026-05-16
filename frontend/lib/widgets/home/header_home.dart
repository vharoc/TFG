import 'package:flutter/material.dart';

class HeaderHome extends StatelessWidget {
  final String? titulo;
  final String modo;
  final VoidCallback? onToggleModo;

  const HeaderHome({
    super.key,
    this.titulo,
    this.modo = 'rapido',
    this.onToggleModo,
  });

  @override
  Widget build(BuildContext context) {
    final bool tieneTitulo = titulo != null && titulo!.isNotEmpty;
    final bool esRapido = modo == 'rapido';

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 245, 230, 186),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEAE4), width: 1),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: tieneTitulo
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 96),
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
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Tooltip(
                message: esRapido ? 'Modo Rápido (toca para activar Pensar)' : 'Modo Pensar (toca para activar Rápido)',
                child: IconButton(
                  onPressed: onToggleModo,
                  icon: Icon(
                    esRapido ? Icons.bolt_rounded : Icons.psychology_rounded,
                    color: esRapido
                        ? const Color(0xFFE07B00)
                        : const Color(0xFF5B6FA6),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
