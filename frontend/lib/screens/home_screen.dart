import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../models/chat_msg.dart';
import '../widgets/chat_input.dart';
import '../widgets/hamburger_btt.dart';
import '../services/chat_services.dart';

class HomeScreen extends StatefulWidget {
  
  final String? chatId;

  const HomeScreen({super.key, this.chatId});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // -- chat activo --
  String? _chatId;
  bool _creandoChat = false;
  bool _cargando = false;

  @override
  void initState(){
    super.initState();
    if(widget.chatId != null){
      _chatId = widget.chatId;
      _cargarMensajes();
    }
  }

  Future<void> _cargarMensajes() async {
    setState() => _cargando = true;
    try{
      final mensajes = await ChatService.instance.cargarMensajes(_chatId);
      if(!mounted) return;
      setState((){
        _messages.clear();
        for(final m in mensaje){
          if(m.tipo == MensajeTipo.texto){
            _messages.add(ChatMessage.text(m.contenido));
          }
        }
      });
      _scrollToBottom();
    }finally {
      if(mounted) setState(() => _cargando = false);
    }
  }

  void _abrirLateral() {
    context.push<bool>('/lateral').then((crearNueva) {
      if (crearNueva == true && mounted) {
        setState(() {
          _chatId = null;
          _messages.clear();
        });
      }
    });
  }

 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addText(String text) async {
    setState(() => _messages.add(ChatMessage.text(text)));
    _scrollToBottom();
    await _esPrimerMensaje(text);
  }

  void _addImg(XFile img) async {
    setState(() => _messages.add(ChatMessage.image(img)));
    _scrollToBottom();
    await _esPrimerMensaje('[Imagen]');
  }

  // -- Crear conversacion en Firestore (solo con el primer mensaje)
  Future<void> _esPrimerMensaje(String primerTexto) async {
    if (_chatId != null || _creandoChat) return;
    _creandoChat = true;

    try {
      final id = await ChatService.instance.crearConversacion(
        titulo: primerTexto.length > 40 ? '${primerTexto.substring(0, 40)}...' : primerTexto,
      );
      if(mounted) setState(() => _chatId = id);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'permission-denied'
          ? 'No tienes permisos en Firestore para crear chats.'
          : 'No se pudo crear la conversacion. Intentalo de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }finally {
      _creandoChat = false;
    }
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

                _buildHeader(),

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
            HamburgerButton(onTap: _abrirLateral),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F4),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0DAD4), width: 1),
        ),
      ),
      child: const SizedBox.expand(),
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