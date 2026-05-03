import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_view_model.dart';
import '../widgets/home/chat_body.dart';
import '../widgets/home/ciudad_selector_sheet.dart';
import '../widgets/home/hamburger_btt.dart';
import '../widgets/home/header_home.dart';

class HomeScreen extends StatefulWidget {
  final String? chatId;

  const HomeScreen({super.key, this.chatId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeViewModel _vm;
  final ScrollController _scrollController = ScrollController();
  bool _mostrandoSelectorCiudad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = HomeViewModel(initialChatId: widget.chatId);
    _vm.addListener(_scrollToBottom);
    _vm.addListener(_onVmChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId == widget.chatId) return;
    _vm.cambiarChat(widget.chatId);
  }

  // Se llama cuando la app vuelve al primer plano (p.ej. al volver de Ajustes)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _vm.gpsPermanentementeDenegado) {
      _inicializar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (_vm.necesitaCiudad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarSelectorSiNecesario());
    }
    if (_vm.mensajeErrorFoto != null) {
      final mensaje = _vm.mensajeErrorFoto!;
      _vm.limpiarErrorFoto();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      });
    }
  }

  Future<void> _inicializar() async {
    await _vm.inicializarUbicacion();
    if (mounted) _mostrarSelectorSiNecesario();
  }

  Future<void> _mostrarSelectorSiNecesario() async {
    if (!_vm.necesitaCiudad || _mostrandoSelectorCiudad || !mounted) return;
    _mostrandoSelectorCiudad = true;

    final ciudad = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CiudadSelectorSheet(),
    );

    _mostrandoSelectorCiudad = false;

    if (ciudad != null && mounted) {
      _vm.seleccionarCiudad(ciudad);
    }
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
