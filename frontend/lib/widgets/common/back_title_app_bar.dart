import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';

class BackTitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const BackTitleAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFAF7F4),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: AppTheme.usal,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: AppTheme.titulo.copyWith(fontSize: 20, color: Colors.black),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
