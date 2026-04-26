import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final String hintText;
  final Color iconColor;
  final VoidCallback onToggleVisibility;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.hintText,
    this.iconColor = Colors.black45,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTheme.cuerpo,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
        suffixIcon: GestureDetector(
          onTap: onToggleVisibility,
          child: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
