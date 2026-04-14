import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', width: 48, height: 48),
          const SizedBox(height: 12),
          Text(
            'Pregunta sobre algún monumento',
            style: AppTheme.cuerpo.copyWith(color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
