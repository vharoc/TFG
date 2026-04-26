import 'package:flutter/material.dart';

import '../common/form_lbl.dart';
import 'auth_password_field.dart';

class AuthLabeledPasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final String hintText;
  final Color iconColor;
  final VoidCallback onToggleVisibility;

  const AuthLabeledPasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.obscure,
    required this.hintText,
    required this.onToggleVisibility,
    this.iconColor = Colors.black45,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormLabel(label),
        const SizedBox(height: 6),
        AuthPasswordField(
          controller: controller,
          obscure: obscure,
          hintText: hintText,
          iconColor: iconColor,
          onToggleVisibility: onToggleVisibility,
        ),
      ],
    );
  }
}
