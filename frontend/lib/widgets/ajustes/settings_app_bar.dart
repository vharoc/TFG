import 'package:flutter/material.dart';

import '../common/back_title_app_bar.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SettingsAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return BackTitleAppBar(title: title);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
