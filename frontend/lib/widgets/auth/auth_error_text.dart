import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class AuthErrorText extends StatelessWidget {
  final String message;

  const AuthErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: AppTheme.usal, fontSize: 13),
      textAlign: TextAlign.center,
    );
  }
}
