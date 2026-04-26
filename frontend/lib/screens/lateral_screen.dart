import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../viewmodels/lateral_view_model.dart';
import '../widgets/lateral/cities_panel.dart';
import '../widgets/lateral/chats_panel.dart';
import '../widgets/lateral/header_lateral.dart';
import '../widgets/lateral/new_chat_button.dart';
import '../widgets/lateral/profile_footer.dart';

class LateralScreen extends StatefulWidget {
  const LateralScreen({super.key});

  @override
  State<LateralScreen> createState() => _LateralScreenState();
}

enum _PanelExpandido { ninguno, chats, ciudades }

class _LateralScreenState extends State<LateralScreen> {
  late final LateralViewModel _vm;
  final ScrollController _chatsScrollController = ScrollController();
  final ScrollController _ciudadesScrollController = ScrollController();
  _PanelExpandido _panelExpandido = _PanelExpandido.ninguno;

  @override
  void initState() {
    super.initState();
    _vm = LateralViewModel();
    _vm.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _chatsScrollController.dispose();
    _ciudadesScrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 760;
    final maxItems = screenHeight < 700 ? 1 : (screenHeight < 820 ? 2 : 3);
    final innerSpacing = isCompact ? 6.0 : 8.0;

    final inicial = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName![0].toUpperCase()
        : (user?.email?.isNotEmpty == true)
        ? user!.email![0].toUpperCase()
        : '?';

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
                        loading: _vm.cargandoChats,
                        chats: _vm.chats,
                        spacing: innerSpacing,
                        maxItems: maxItems,
                        scrollController: _chatsScrollController,
                        onChatTap: (chat) => context.pop(chat.id),
                        onDeleteChat: (chat) => _vm.eliminarChat(chat.id),
                        onExpand: () {},
                        onCollapse: () => setState(
                          () => _panelExpandido = _PanelExpandido.ninguno,
                        ),
                      )
                    : _panelExpandido == _PanelExpandido.ciudades
                    ? LateralCitiesPanel(
                        expanded: true,
                        loading: _vm.cargandoCiudades,
                        ciudades: _vm.ciudades,
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
                            loading: _vm.cargandoChats,
                            chats: _vm.chats,
                            spacing: innerSpacing,
                            maxItems: maxItems,
                            scrollController: _chatsScrollController,
                            onChatTap: (chat) => context.pop(chat.id),
                            onDeleteChat: (chat) => _vm.eliminarChat(chat.id),
                            onExpand: () => setState(
                              () => _panelExpandido = _PanelExpandido.chats,
                            ),
                            onCollapse: () {},
                          ),
                          SizedBox(height: innerSpacing),
                          LateralCitiesPanel(
                            expanded: false,
                            loading: _vm.cargandoCiudades,
                            ciudades: _vm.ciudades,
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
              inicial: inicial,
              nombre: user?.displayName ?? user?.email ?? 'Usuario',
              onProfileTap: () => context.push('/perfil'),
              onSettingsTap: () => context.push('/ajustes'),
            ),
          ],
        ),
      ),
    );
  }
}
