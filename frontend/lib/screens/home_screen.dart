import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme.dart';
import '../models/chat_msg.dart';
import '../widgets/chat_input.dart';
import '../widgets/hamburger_btt.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addText(String text){
    setState(() => _messages.add(ChatMessage.text(text)));
    _scrollToBottom();
  }

  void _addImg(XFile img){
    setState(() => _messages.add(ChatMessage.image(img)));
    _scrollToBottom();
  }

  void _scrollToBottom(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(_scrollController.hasClients){
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [

                // ── Área de mensajes ────────────────────────
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _buildBubble(_messages[i]),
                        ),
                ),
 
                // ── Caja de texto ───────────────────────────
                ChatInput(
                  onSend: _addText,
                  onImagePicked: _addImg,
                ),
              ],
            ),
 
            // ── Botón hamburguesa ────────────────────────
            HamburgerButton(onTap: () => context.push('/lateral')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png', // ajusta esta ruta a tu asset real
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Pregunta sobre algún monumento',
            style: AppTheme.cuerpo.copyWith(color: Colors.black38),
          ),
        ],
      ),
    );
  }
 
  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppTheme.usal,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: switch (msg.type) {
          MessageType.text => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                msg.text!,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          MessageType.image => Image.file(
              File(msg.image!.path),
              fit: BoxFit.cover,
            ),
        },
      ),
    );
  }

}