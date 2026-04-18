import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/home_view_model.dart';
import '../widgets/home/chat_input.dart';
import '../widgets/home/chat_bubble.dart';
import '../widgets/home/hamburger_btt.dart';
import '../widgets/home/home_empty_state.dart';
import '../widgets/home/header_home.dart';

class HomeScreen extends StatefulWidget {
  final String? chatId;

  const HomeScreen({super.key, this.chatId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _vm;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel(initialChatId: widget.chatId);
    _vm.addListener(() {
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId == widget.chatId) return;
    _vm.cambiarChat(widget.chatId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                HeaderHome(titulo: _vm.tituloChat),
                // const Divider(height: 100, indent: 20, endIndent: 20, color: Colors.black,),

                // ── Área de mensajes ──
                Expanded(
                  child: _vm.cargando
                      ? const Center(child: CircularProgressIndicator())
                      : _vm.messages.isEmpty
                      ? const HomeEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          itemCount: _vm.messages.length,
                          itemBuilder: (_, i) =>
                              ChatBubble(mensaje: _vm.messages[i]),
                        ),
                ),

                // ── Caja de texto ──
                ChatInput(
                  onSend: _vm.enviarTexto,
                  onImagePicked: _vm.enviarImagen,
                ),
              ],
            ),

            // ── Botón hamburguesa ──
            HamburgerButton(onTap: _abrirLateral),
          ],
        ),
      ),
    );
  }

  void _abrirLateral() {
    context.push<dynamic>('/lateral').then((resultado) {
      if (!mounted) return;
      if (resultado is String) {
        _vm.cambiarChat(resultado);
      } else if (resultado == true) {
        _vm.nuevaConversacion();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
