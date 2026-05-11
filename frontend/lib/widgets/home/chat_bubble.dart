import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/mensaje.dart';
import '../../theme/theme.dart';

class ChatBubble extends StatelessWidget {
  final Mensaje mensaje;

  const ChatBubble({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.role == MensajeRole.usuario;

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
              : Image.file(
                  File(mensaje.imgUrl!),
                  fit: BoxFit.cover,
                ),
        },
      ),
    );
  }
}
