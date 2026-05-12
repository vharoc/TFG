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

    final burbujaAligned = Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: burbuja,
    );

    if (!mostrarChips) return burbujaAligned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        burbujaAligned,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...mensaje.poisCercanos.map((poi) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: FilledButton(
                      onPressed: () => onPoiTap?.call(poi),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.ocre,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                      ),
                      child: Text(
                        poi.nombre,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}
