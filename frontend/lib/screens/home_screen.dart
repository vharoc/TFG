import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController _controller = TextEditingController();
  bool _showSend = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                  'Bienvenido a',
                  style: AppTheme.titulo.copyWith(fontSize: 24),
                  ),
                  Text(
                    'TourClick',
                    style: AppTheme.titulo.copyWith(
                      fontSize: 32,
                      color: AppTheme.usal,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra inferior
          _buildCajaTexto(),
          
        ]
          
        
      ),
    );
  }



  Widget _buildCajaTexto(){
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          
          // ── Campo de texto ───────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),                  // altura máxima antes de scroll

            child: Scrollbar(
              child: SingleChildScrollView(
                child: TextField(
                  controller: _controller,
                  maxLines: null,               // permite crecer
                  keyboardType: TextInputType.multiline,
                  
                  onChanged: (value) {
                    setState(() {
                      _showSend = value.trim().isNotEmpty;
                    });
                  },

                  style: AppTheme.cuerpo.copyWith(color: Colors.black),

                  decoration: const InputDecoration(
                    hintText: 'Pregunta sobre algún monumento',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
          
          Row(
            children: [ 
              // - BOTÓN "+" ─────────────────────────────
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _showAttachMenu(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
    
              const Spacer(),

              // - Botón enviar ─────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _showSend
                    ? GestureDetector(
                        key: const ValueKey('send'),
                        onTap: () {
                          print(_controller.text);
                          _controller.clear();
                          setState(() => _showSend = false);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.usal,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttachMenu(BuildContext context){
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset pos = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context, 
      color: Colors.white, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy-130, overlay.size.width - pos.dx - button.size.width, 0),

      items: [
        // ── Cámara ──────────────────────────────
        PopupMenuItem<String>(
          value: 'camara',
          child: _menuRow(Icons.camera_alt_outlined, 'Cámara'),
        ),
        // ── Álbum ───────────────────────────────
        PopupMenuItem<String>(
          value: 'album',
          child: _menuRow(Icons.photo_library_outlined, 'Álbum de fotos'),
        ),

      ],
    
    ).then((value) {
      if (value == 'camara') {
        // TODO: abrir cámara
      } else if (value == 'album') {
        // TODO: abrir galería
      }
    });
  }

  Widget _menuRow(IconData icon, String label, {bool hasArrow = false}){
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if(hasArrow) const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ],
    );
  }

}