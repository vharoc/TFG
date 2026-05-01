import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../viewmodels/lateral_view_model.dart';
import '../widgets/lateral/cities_panel.dart';
import '../widgets/lateral/chats_panel.dart';
import '../widgets/lateral/header_lateral.dart';
import '../widgets/lateral/new_chat_button.dart';
import '../widgets/lateral/profile_footer.dart';

enum _PanelExpandido { ninguno, chats, ciudades }

class LateralScreen extends StatelessWidget {
  const LateralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LateralViewModel(),
      child: const _LateralBody(),
    );
  }
}

class _LateralBody extends StatefulWidget {
  const _LateralBody();

  @override
  State<_LateralBody> createState() => _LateralBodyState();
}

class _LateralBodyState extends State<_LateralBody> {
  final ScrollController _chatsScrollController = ScrollController();
  final ScrollController _ciudadesScrollController = ScrollController();
  _PanelExpandido _panelExpandido = _PanelExpandido.ninguno;

  @override
  void dispose() {
    _chatsScrollController.dispose();
    _ciudadesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LateralViewModel>();
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 760;
    final maxItems = screenHeight < 700 ? 1 : (screenHeight < 820 ? 2 : 3);
    final innerSpacing = isCompact ? 6.0 : 8.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            const HeaderLateral(),
            const Divider(height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 12),

            // NUEVA CONVERSACIÓN
            LateralNewChatButton(
              isCompact: isCompact,
              onTap: () => context.pop(true),
            ),

            const SizedBox(height: 16),

            // LISTAS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _panelExpandido == _PanelExpandido.chats
                    ? LateralChatsPanel(
                        expanded: true,
                        loading: vm.cargandoChats,
                        chats: vm.chats,
                        spacing: innerSpacing,
                        maxItems: maxItems,
                        scrollController: _chatsScrollController,
                        onChatTap: (chat) => context.pop(chat.id),
                        onDeleteChat: _confirmarEliminarChat,
                        onExpand: () {},
                        onCollapse: () => setState(
                          () => _panelExpandido = _PanelExpandido.ninguno,
                        ),
                      )
                    : _panelExpandido == _PanelExpandido.ciudades
                    ? LateralCitiesPanel(
                        expanded: true,
                        loading: vm.cargandoCiudades,
                        ciudades: vm.ciudades,
                        spacing: innerSpacing,
                        maxItems: maxItems,
                        scrollController: _ciudadesScrollController,
                        onCiudadTap: (_) => context.pop(),
                        onExpand: () {},
                        onCollapse: () => setState(
                          () => _panelExpandido = _PanelExpandido.ninguno,
                        ),
                      )
                    : Column(
                        children: [
                          LateralChatsPanel(
                            expanded: false,
                            loading: vm.cargandoChats,
                            chats: vm.chats,
                            spacing: innerSpacing,
                            maxItems: maxItems,
                            scrollController: _chatsScrollController,
                            onChatTap: (chat) => context.pop(chat.id),
                            onDeleteChat: _confirmarEliminarChat,
                            onExpand: () => setState(
                              () => _panelExpandido = _PanelExpandido.chats,
                            ),
                            onCollapse: () {},
                          ),
                          SizedBox(height: innerSpacing),
                          LateralCitiesPanel(
                            expanded: false,
                            loading: vm.cargandoCiudades,
                            ciudades: vm.ciudades,
                            spacing: innerSpacing,
                            maxItems: maxItems,
                            scrollController: _ciudadesScrollController,
                            onCiudadTap: (_) => context.pop(),
                            onExpand: () => setState(
                              () => _panelExpandido = _PanelExpandido.ciudades,
                            ),
                            onCollapse: () {},
                          ),
                        ],
                      ),
              ),
            ),

            // FOOTER
            const Divider(height: 1, indent: 20, endIndent: 20),
            LateralProfileFooter(
              inicial: vm.inicial,
              nombre: vm.nombre,
              onProfileTap: () => context.push('/perfil'),
              onSettingsTap: () => context.push('/ajustes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarChat(Chat chat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text(
          '¿Seguro que quieres eliminar esta conversación? No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<LateralViewModel>().eliminarChat(chat.id);
    }
  }
}
