import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class StopMarker extends StatelessWidget {
  final int number;
  final bool isCurrent;
  final bool isVisited;

  const StopMarker({
    super.key,
    required this.number,
    this.isCurrent = false,
    this.isVisited = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isVisited
        ? Colors.grey.shade400
        : isCurrent
            ? AppTheme.usal
            : AppTheme.ocre;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: isVisited
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : Text(
              '$number',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCurrent ? 14 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
