import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class AuthSwitchLink extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;

  const AuthSwitchLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(prefix, style: const TextStyle(color: Colors.black54)),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: TextStyle(color: AppTheme.usal, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
