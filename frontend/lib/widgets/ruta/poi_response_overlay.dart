import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../theme/theme.dart';

class PoiResponseOverlay extends StatelessWidget {
  final String? texto;
  final bool loading;
  final VoidCallback onClose;
  final double bottomOffset;

  const PoiResponseOverlay({
    super.key,
    required this.texto,
    required this.loading,
    required this.onClose,
    this.bottomOffset = 240,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: bottomOffset,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.ocre),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Clicky responde',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.ocre,
                      ),
                    ),
                  ),
                )
              else if (texto != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: GptMarkdown(
                      texto!,
                      style: const TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
