import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mensaje.dart';
import '../../models/poi_sugerido.dart';
import '../../theme/theme.dart';

class ChatBubble extends StatelessWidget {
  final Mensaje mensaje;
  final void Function(PoiSugerido)? onPoiTap;

  const ChatBubble({super.key, required this.mensaje, this.onPoiTap});

  Future<void> _abrirMaps() async {
    final nav = mensaje.navegacion!;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${nav.lat},${nav.lon}'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.role == MensajeRole.usuario;
    final tieneNavegacion = !esUsuario && mensaje.navegacion != null;
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
          // El usuario escribe texto plano; el bot puede devolver Markdown.
          child: esUsuario
              ? Text(
                  mensaje.contenido!,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                )
              : GptMarkdownTheme(
                  gptThemeData: GptMarkdownThemeData(
                    brightness: Brightness.light,
                    h1: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                    h2: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    h3: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    h4: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    h5: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                    h6: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  child: GptMarkdown(
                    mensaje.contenido!,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
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

    if (!mostrarChips && !tieneNavegacion) return burbujaAligned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        burbujaAligned,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mostrarChips)
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
              if (tieneNavegacion)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: OutlinedButton.icon(
                    onPressed: _abrirMaps,
                    icon: const Icon(Icons.directions_walk_rounded, size: 18),
                    label: Text(
                      'Cómo llegar a ${mensaje.navegacion!.nombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.usal,
                      side: const BorderSide(color: AppTheme.usal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }
}
