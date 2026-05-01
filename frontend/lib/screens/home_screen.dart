import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_view_model.dart';
import '../widgets/home/chat_body.dart';
import '../widgets/home/hamburger_btt.dart';
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
    _vm.addListener(_scrollToBottom);
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
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) => Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    HeaderHome(titulo: vm.tituloChat),
                    Expanded(
                      child: HomeChatBody(
                        cargando: vm.cargando,
                        messages: vm.messages,
                        scrollController: _scrollController,
                        onSend: vm.enviarTexto,
                        onImagePicked: vm.enviarImagen,
                      ),
                    ),
                  ],
                ),

                HamburgerButton(onTap: _abrirLateral),
              ],
            ),
          ),
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
