import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'package:go_router/go_router.dart';

class HeaderLateral extends StatelessWidget{

  const HeaderLateral({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}