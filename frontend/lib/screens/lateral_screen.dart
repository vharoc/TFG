import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../models/chat.dart';
import '../models/ciudad.dart';
import '../viewmodels/lateral_view_model.dart';
import '../widgets/lateral/header_lateral.dart';
import '../widgets/lateral/section_header.dart';

class LateralScreen extends StatefulWidget {
  const LateralScreen({super.key});

  @override
  State<LateralScreen> createState() => _LateralScreenState();
}

class _LateralScreenState extends State<LateralScreen> {
  late final LateralViewModel _vm;

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => context.pop(true),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isCompact ? 10 : 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.usal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Nueva conversación',
                        style: AppTheme.cuerpo.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // LISTAS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ── Historial de chats ──
                    const SectionHeader(header: 'Historial de chats'),
                    SizedBox(height: innerSpacing),
                    Flexible(
                      child: _vm.cargandoChats
                          ? const Center(child: CircularProgressIndicator())
                          : _vm.chats.isEmpty
                              ? _buildEmptyCard('Aún no hay conversaciones')
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ..._vm.chats
                                        .take(maxItems)
                                        .map((c) => _buildChatTile(c)),
                                    _buildVerTodo(onTap: () {}),
                                  ],
                                ),
                    ),

                    SizedBox(height: innerSpacing),

                    // ── Ciudades visitadas ──
                    const SectionHeader(header: 'Ciudades visitadas'),
                    SizedBox(height: innerSpacing),
                    Flexible(
                      child: _vm.cargandoCiudades
                          ? const Center(child: CircularProgressIndicator())
                          : _vm.ciudades.isEmpty
                              ? _buildEmptyCard(
                                  'Aún no has visitado ninguna ciudad',
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ..._vm.ciudades
                                        .take(maxItems)
                                        .map((c) => _buildCiudadTile(c)),
                                    _buildVerTodo(onTap: () {}),
                                  ],
                                ),
                    ),
                  ],
                ),
              ),
            ),

            // FOOTER
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  // Avatar → navega a Perfil
                  GestureDetector(
                    onTap: () => context.push('/perfil'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppTheme.usal,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          inicial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.displayName ?? user?.email ?? 'Usuario',
                      style: AppTheme.cuerpo.copyWith(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Icono tuerca → navega a Ajustes
                  IconButton(
                    onPressed: () => context.push('/ajustes'),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.black54,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: const Icon(
          Icons.chat_bubble_outline,
          size: 18,
          color: AppTheme.usal,
        ),
        title: Text(
          chat.titulo,
          style: AppTheme.cuerpo.copyWith(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatFecha(chat.fechaCreacion),
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.black38,
          ),
          onPressed: () => _vm.eliminarChat(chat.id),
        ),
        onTap: () => context.pop(chat.id),
      ),
    );
  }

  Widget _buildCiudadTile(Ciudad ciudad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: const Icon(
          Icons.location_city_outlined,
          size: 18,
          color: AppTheme.usal,
        ),
        title: Text(
          ciudad.nombre,
          style: AppTheme.cuerpo.copyWith(fontSize: 14),
        ),
        onTap: () => context.pop(),
      ),
    );
  }

  Widget _buildVerTodo({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Ver todo',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.usal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: AppTheme.usal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String mensaje) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: Center(
        child: Text(
          mensaje,
          style: const TextStyle(fontSize: 13, color: Colors.black38),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diff = DateTime.now().difference(fecha).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}