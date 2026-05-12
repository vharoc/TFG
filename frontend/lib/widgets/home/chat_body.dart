import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/mensaje.dart';
import '../../models/poi_sugerido.dart';
import 'chat_input.dart';
import 'messages_list.dart';

class HomeChatBody extends StatelessWidget {
  final bool cargando;
  final List<Mensaje> messages;
  final ScrollController scrollController;
  final Future<void> Function(String texto) onSend;
  final Future<void> Function(XFile image) onImagePicked;
  final void Function(PoiSugerido)? onPoiTap;

  const HomeChatBody({
    super.key,
    required this.cargando,
    required this.messages,
    required this.scrollController,
    required this.onSend,
    required this.onImagePicked,
    this.onPoiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: HomeMessagesList(
            cargando: cargando,
            messages: messages,
            controller: scrollController,
            onPoiTap: onPoiTap,
          ),
        ),
        ChatInput(onSend: onSend, onImagePicked: onImagePicked),
      ],
    );
  }
}
