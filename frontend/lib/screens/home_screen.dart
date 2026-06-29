import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/ruta_result.dart';
import 'ruta_navegacion_screen.dart';
import '../services/auth_services.dart';
import '../services/ubicacion_service.dart';
import '../services/user_services.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/home/chat_body.dart';
import '../widgets/home/ciudad_selector_sheet.dart';
import '../widgets/home/hamburger_btt.dart';
import '../widgets/home/header_home.dart';
import '../widgets/home/ruta_exit_button.dart';
import '../widgets/home/ruta_resumen_sheet.dart';

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
  bool _mostrandoResumenRuta = false;
  bool _navegacionAbierta = false;
  // true cuando el usuario sale del mapa con atrás pero sin cancelar la ruta
  bool _navegacionMinimizada = false;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = HomeViewModel(initialChatId: widget.chatId);
    _vm.addListener(_onVmChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId == widget.chatId) return;
    _vm.cambiarChat(widget.chatId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
    _scrollToBottomIfNeeded();

    if (_vm.necesitaCiudad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarSelectorSiNecesario());
    }
    if (_vm.rutaState?.estado == EstadoRuta.mostrandoResumen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarResumenRutaSiNecesario());
    }
    if (_vm.rutaState?.estado == EstadoRuta.activo &&
        !_navegacionAbierta &&
        !_navegacionMinimizada) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _abrirNavegacion());
    }
    if (_vm.rutaState == null && _navegacionMinimizada) {
      _navegacionMinimizada = false;
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

  Future<void> _mostrarResumenRutaSiNecesario() async {
    final resultado = _vm.rutaState?.resultado;
    if (resultado == null || _mostrandoResumenRuta || !mounted) return;
    _mostrandoResumenRuta = true;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RutaResumenSheet(
        resultado: resultado,
        onComenzar: () {
          Navigator.of(context).pop();
          _vm.comenzarRuta();
        },
        onCancelar: () {
          Navigator.of(context).pop();
          _vm.cancelarRuta();
        },
      ),
    );

    _mostrandoResumenRuta = false;
  }

  Future<void> _abrirNavegacion() async {
    if (_navegacionAbierta || !mounted) return;
    _navegacionAbierta = true;
    if (_navegacionMinimizada) setState(() => _navegacionMinimizada = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _vm,
          child: const RutaNavegacionScreen(),
        ),
      ),
    );

    _navegacionAbierta = false;
    if (_vm.rutaState?.estado == EstadoRuta.activo && mounted) {
      setState(() => _navegacionMinimizada = true);
    }
  }

  void _scrollToBottomIfNeeded() {
    final newCount = _vm.messages.length;
    if (newCount <= _previousMessageCount) return;
    _previousMessageCount = newCount;

    final shouldScroll = !_scrollController.hasClients ||
        (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            150);
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _inicializar() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await UserServices.instance.ensureUsuario(user);
      }
      await Future.wait([
        _vm.inicializarUbicacion(),
        UbicacionService.instance.cargarCiudadesSoportadas(),
      ]);
    } catch (_) {
      // Un fallo de Firebase o del plugin de ubicación no debe dejar la
      // pantalla colgada en loading: igualmente intentamos abrir el selector.
    } finally {
      if (mounted) _mostrarSelectorSiNecesario();
    }
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
                    HeaderHome(
                      titulo: vm.tituloChat,
                    ),
                    Expanded(
                      child: HomeChatBody(
                        cargando: vm.cargando,
                        messages: vm.messages,
                        scrollController: _scrollController,
                        onSend: vm.enviarTexto,
                        onImagePicked: vm.enviarImagen,
                        onPoiTap: vm.preguntarSobrePoi,
                        generando: vm.generando,
                        poiCargandoKey: vm.poiCargandoKey,
                        onCancelar: vm.cancelarRespuesta,
                        modo: vm.modo,
                        onModoChanged: vm.setModo,
                        rutaState: vm.rutaState,
                        onFiltroRuta: vm.seleccionarFiltroRuta,
                        onSiguienteParada: vm.siguienteParada,
                        onCancelarRuta: vm.cancelarRuta,
                        onIniciarRuta: vm.iniciarFlujoRuta,
                        ciudad: vm.ciudadActual,
                      ),
                    ),
                  ],
                ),

                HamburgerButton(onTap: _abrirLateral),

                if (vm.rutaState?.estado == EstadoRuta.activo &&
                    _navegacionMinimizada)
                  RutaExitButton(
                    icon: Icons.map_rounded,
                    label: 'Volver al mapa',
                    onTap: _abrirNavegacion,
                  )
                else if (vm.rutaState != null)
                  RutaExitButton(
                    onTap: () {
                      setState(() => _navegacionMinimizada = false);
                      _vm.cancelarRuta();
                    },
                  ),
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
}
