import 'package:flutter/material.dart';

import '../../models/mensaje.dart';
import '../../models/poi_sugerido.dart';
import 'chat_bubble.dart';
import 'home_empty_state.dart';

class HomeMessagesList extends StatelessWidget {
  final bool cargando;
  final List<Mensaje> messages;
  final ScrollController controller;
  final void Function(PoiSugerido)? onPoiTap;
  final bool bloqueado;
  final String? poiCargandoKey;

  const HomeMessagesList({
    super.key,
    required this.cargando,
    required this.messages,
    required this.controller,
    this.onPoiTap,
    this.bloqueado = false,
    this.poiCargandoKey,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Center(
        child: Image.asset('assets/images/logo_only.png', width: 72, height: 72),
      );
    }

    if (messages.isEmpty) {
      return const HomeEmptyState();
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      cacheExtent: 600,
      itemCount: messages.length,
      itemBuilder: (_, i) => RepaintBoundary(
        child: ChatBubble(
          mensaje: messages[i],
          onPoiTap: onPoiTap,
          bloqueado: bloqueado,
          poiCargandoKey: poiCargandoKey,
        ),
      ),
    );
  }
}
