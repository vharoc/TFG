import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ruta_result.dart';
import '../../theme/theme.dart';

class ChatInput extends StatefulWidget {
  final void Function(String text)? onSend;
  final void Function(XFile image)? onImagePicked;
  final bool isLoading;
  final VoidCallback? onCancel;
  final String modo;
  final void Function(String modo)? onModoChanged;
  final RutaState? rutaState;
  final void Function(String filtro)? onFiltroRuta;
  final VoidCallback? onSiguienteParada;
  final VoidCallback? onCancelarRuta;
  final VoidCallback? onIniciarRuta;

  const ChatInput({
    super.key,
    this.onSend,
    this.onImagePicked,
    this.isLoading = false,
    this.onCancel,
    this.modo = 'rapido',
    this.onModoChanged,
    this.rutaState,
    this.onFiltroRuta,
    this.onSiguienteParada,
    this.onCancelarRuta,
    this.onIniciarRuta,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _showSend = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      widget.onImagePicked?.call(photo);
    }
  }

  Future<void> _openGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (photo != null) {
      widget.onImagePicked?.call(photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) return _buildLoading();
    final rs = widget.rutaState;
    if (rs != null) {
      if (rs.estado == EstadoRuta.esperandoFoto) return _buildEsperandoFoto();
      if (rs.estado == EstadoRuta.seleccionandoFiltro) return _buildFiltroRuta();
      if (rs.estado == EstadoRuta.cargando) return _buildCargandoRuta();
      if (rs.estado == EstadoRuta.activo) return _buildRutaActiva();
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Campo de texto ───────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
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
              // ── Botón "+" ────────────────────────────────
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _showAttachMenu(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ── Selector de modo (estilo Gemini) ─────────
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _showModoMenu(ctx),
                  child: _ModoChip(modo: widget.modo),
                ),
              ),

              const SizedBox(width: 6),

              // ── Botón ruta ────────────────────────────────
              GestureDetector(
                onTap: widget.onIniciarRuta,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: const Icon(
                    Icons.route_rounded,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ),

              const Spacer(),

              // ── Botón enviar ─────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _showSend
                    ? GestureDetector(
                        key: const ValueKey('send'),
                        onTap: () {
                          widget.onSend?.call(_controller.text);
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
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.ocre),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Clicky está generando...',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: widget.onCancel,
            child: const Icon(Icons.close_rounded, color: Colors.black54, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildEsperandoFoto() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const Icon(Icons.camera_alt_outlined, size: 18, color: AppTheme.ocre),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Toma una foto del lugar donde estás',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.ocre,
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onCancelarRuta,
            child: const Icon(Icons.close_rounded, size: 20, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroRuta() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Elige el tipo de ruta',
                style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: widget.onCancelarRuta,
              child: const Icon(Icons.close_rounded, size: 20, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _rutaChip('Todos', 'todos', AppTheme.usal),
            const SizedBox(width: 8),
            _rutaChip('Pendientes', 'pendientes', AppTheme.ocre),
            const SizedBox(width: 8),
            _rutaChip('Visitados', 'visitados', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _rutaChip(String label, String value, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onFiltroRuta?.call(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildCargandoRuta() {
    return const SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.ocre),
          ),
          SizedBox(width: 12),
          Text('Calculando tu ruta...', style: TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRutaActiva() {
    final rs = widget.rutaState!;
    final parada = rs.paradaActualObj;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const Icon(Icons.route_rounded, size: 16, color: AppTheme.usal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parada != null
                  ? '${rs.paradaActual + 1}/${rs.totalParadas}: ${parada.nombre}'
                  : 'Ruta activa',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          // Cámara — toma foto y auto-avanza tras la respuesta
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.ocre,
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          // Saltar — avanza sin foto
          GestureDetector(
            onTap: widget.onSiguienteParada,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.usal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Saltar →',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onCancelarRuta,
            child: const Icon(Icons.close_rounded, size: 20, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  void _showAttachMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset pos = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy - 130,
        overlay.size.width - pos.dx - button.size.width,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'camara',
          child: _menuRow(Icons.camera_alt_outlined, 'Cámara'),
        ),
        PopupMenuItem<String>(
          value: 'album',
          child: _menuRow(Icons.photo_library_outlined, 'Álbum de fotos'),
        ),
      ],
    ).then((value) {
      if (value == 'camara') {
        _openCamera();
      } else if (value == 'album') {
        _openGallery();
      }
    });
  }

  void _showModoMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset pos = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<String>(
      context: context,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy - 120,
        overlay.size.width - pos.dx - button.size.width,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rapido',
          child: _modoRow(
            Icons.bolt_rounded,
            'Rápido',
            const Color(0xFFE07B00),
            widget.modo == 'rapido',
          ),
        ),
        PopupMenuItem<String>(
          value: 'pensar',
          child: _modoRow(
            Icons.psychology_rounded,
            'Pensar',
            const Color(0xFF5B6FA6),
            widget.modo == 'pensar',
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        widget.onModoChanged?.call(value);
      }
    });
  }

  Widget _menuRow(IconData icon, String label, {bool hasArrow = false}) {
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
        if (hasArrow)
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ],
    );
  }

  Widget _modoRow(IconData icon, String label, Color color, bool selected) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (selected) Icon(Icons.check_rounded, size: 18, color: color),
      ],
    );
  }
}

class _ModoChip extends StatelessWidget {
  final String modo;

  const _ModoChip({required this.modo});

  @override
  Widget build(BuildContext context) {
    final bool esRapido = modo == 'rapido';
    final Color color = esRapido ? const Color(0xFFE07B00) : const Color(0xFF5B6FA6);
    final Color bgColor = esRapido ? const Color(0xFFFFF3E0) : const Color(0xFFEDE7F6);
    final Color borderColor = esRapido
        ? const Color(0xFFE07B00).withValues(alpha: 0.35)
        : const Color(0xFF5B6FA6).withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esRapido ? Icons.bolt_rounded : Icons.psychology_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            esRapido ? 'Rápido' : 'Pensar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 1),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
        ],
      ),
    );
  }
}
