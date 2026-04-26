import 'package:flutter/material.dart';

import '../common/back_title_app_bar.dart';

class PerfilAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const PerfilAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return BackTitleAppBar(title: title);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
