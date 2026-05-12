import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/mensaje.dart';
import '../../models/poi_sugerido.dart';
import '../../theme/theme.dart';

class ChatBubble extends StatelessWidget {
  final Mensaje mensaje;
  final void Function(PoiSugerido)? onPoiTap;

  const ChatBubble({super.key, required this.mensaje, this.onPoiTap});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.role == MensajeRole.usuario;
    final mostrarChips = !esUsuario && mensaje.poisCercanos.isNotEmpty;

    final burbuja = Container(
      margin: EdgeInsets.only(bottom: mostrarChips ? 6 : 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: esUsuario ? AppTheme.usal : const Color(0xFFF0EDE9),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: switch (mensaje.tipo) {
        MensajeTipo.texto => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            mensaje.contenido!,
            style: TextStyle(
              color: esUsuario ? Colors.white : Colors.black,
              fontSize: 15,
            ),
          ),
        ),
        MensajeTipo.imagen => mensaje.imgUrl!.startsWith('http')
            ? Image.network(
                mensaje.imgUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              )
            : Image.file(File(mensaje.imgUrl!), fit: BoxFit.cover),
      },
    );

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: mostrarChips
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                burbuja,
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: mensaje.poisCercanos
                        .map((poi) => ActionChip(
                              label: Text(
                                poi.nombre,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => onPoiTap?.call(poi),
                              backgroundColor: AppTheme.fondo,
                              side: const BorderSide(color: AppTheme.ocre),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ),
              ],
            )
          : burbuja,
    );
  }
}
