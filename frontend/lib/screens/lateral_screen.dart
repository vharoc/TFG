import '../theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_services.dart';

// MODELOS TEMPORALES 
class ChatHistorial {
  final String id;
  final String titulo;
  final DateTime fecha;
  const ChatHistorial({required this.id, required this.titulo, required this.fecha});
}

class CiudadVisitada {
  final String id;
  final String nombre;
  final String provincia;
  const CiudadVisitada({required this.id, required this.nombre, required this.provincia});
}

// PANTALLA 
class LateralScreen extends StatefulWidget{
  const LateralScreen ({super.key});

  @override
  State<LateralScreen> createState() => _LateralScreenState();
}

class _LateralScreenState extends State<LateralScreen> {

  static final List<ChatHistorial> _chats = [
    ChatHistorial(id: '1', titulo: 'Catedral de Salamanca', fecha: DateTime(2025, 4, 1)),
    ChatHistorial(id: '2', titulo: 'Plaza Mayor',            fecha: DateTime(2025, 3, 28)),
    ChatHistorial(id: '3', titulo: 'Casa de las Conchas',    fecha: DateTime(2025, 3, 20)),
  ];
 
  static final List<CiudadVisitada> _ciudades = [
    CiudadVisitada(id: '1', nombre: 'Salamanca', provincia: 'España'),
    CiudadVisitada(id: '2', nombre: 'Toledo',    provincia: 'España'),
    CiudadVisitada(id: '3', nombre: 'Ávila',     provincia: 'España'),
  ];

  @override
  Widget build(BuildContext context){
    
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 760;
    final maxItemsPerSection = screenHeight < 700 ? 1 : (screenHeight < 820 ? 2 : 3);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tour',
                          style: AppTheme.titulo.copyWith(
                            fontSize: 26,
                            color: AppTheme.usal,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(
                          text: 'Click',
                          style: AppTheme.titulo.copyWith(
                            fontSize: 26,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.usal, size: 20),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: (){
                  // Crear nueva conversacion
                  context.pop();
                },

                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12, horizontal: 16),
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

            // Lista 
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSectionHeader('Historial de chats'),
                    SizedBox(height: innerSpacing),
                    // ── Historial de chats desde Firestore ─────────────────
                    Flexible(
                      flex: 1,
                      child: StreamBuilder<List<ConversacionMeta>>(
                        stream: ChatService.instance.chatsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final chats = snapshot.data ?? [];
                          if (chats.isEmpty) {
                            return _buildEmptyCard(
                                'Aún no hay conversaciones');
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...chats
                                  .take(maxItemsPerSection)
                                  .map((c) => _buildChatTile(context, c)),
                              _buildVerTodo(context, onTap: () {}),
                            ],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 8),

                    _buildSectionHeader('Ciudades visitadas'),

                    SizedBox(height: innerSpacing),
                    // Ciudades ocupan la otra mitad
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_ciudades.isEmpty)
                            _buildEmptyCard('Aún no has visitado ninguna ciudad')
                          else ...[
                            ..._ciudades.take(maxItemsPerSection).map((c) => _buildCiudadTile(context, c)),
                            _buildVerTodo(context, onTap: () {}),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(), // empuja el footer hacia abajo
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
                  // Avatar usuario
                  GestureDetector(
                    onTap: () {
                      context.push('/ajustes');
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
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
 
                  // Nombre / email
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
 
                  // Botón configuración
                  IconButton(
                    onPressed: () {
                      // nav a configuacion
                      context.push('/ajustes');
                    },
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.black54, size: 22),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.black,
      ),
    );
  }

  // ── Tile de chat con opción de eliminar ────────────────────────────────────
  Widget _buildChatTile(BuildContext context, ConversacionMeta chat) {
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
        leading: const Icon(Icons.chat_bubble_outline,
            size: 18, color: AppTheme.usal),
        title: Text(
          chat.titulo,
          style: AppTheme.cuerpo.copyWith(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatFecha(chat.fecha),
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        trailing: IconButton(
          icon:
              const Icon(Icons.delete_outline, size: 18, color: Colors.black38),
          onPressed: () => _confirmarEliminarChat(context, chat),
        ),
        onTap: () => context.pop(),
      ),
    );
  }
 
  // ── Diálogo de confirmación antes de eliminar ──────────────────────────────
  Future<void> _confirmarEliminarChat(
      BuildContext context, ConversacionMeta chat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: Text('¿Eliminar "${chat.titulo}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ChatService.instance.eliminarConversacion(chat.id);
    }
  }


 Widget _buildCiudadTile(BuildContext context, CiudadVisitada ciudad) {
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
        leading: const Icon(Icons.location_city_outlined,
            size: 18, color: AppTheme.usal),
        title: Text(
          ciudad.nombre,
          style: AppTheme.cuerpo.copyWith(fontSize: 14),
        ),
        subtitle: Text(
          ciudad.provincia,
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        onTap: () => context.pop(),
      ),
    );
  }

  Widget _buildVerTodo(BuildContext context, {required VoidCallback onTap}) {
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
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: AppTheme.usal),
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