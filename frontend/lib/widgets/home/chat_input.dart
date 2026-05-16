import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/theme.dart';

class ChatInput extends StatefulWidget {
  // Callback que se ejecuta al pulsar enviar con el texto introducido.
  final void Function(String text)? onSend;
  final void Function(XFile image)? onImagePicked;
  final bool isLoading;
  final VoidCallback? onCancel;

  const ChatInput({
    super.key,
    this.onSend,
    this.onImagePicked,
    this.isLoading = false,
    this.onCancel,
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
      child: widget.isLoading ? _buildLoading() : Column(
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
      ),
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
}
