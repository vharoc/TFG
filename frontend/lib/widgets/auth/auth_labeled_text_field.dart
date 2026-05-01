import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../common/form_lbl.dart';

class AuthLabeledTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool obscure;
  final Color iconColor;
  final VoidCallback? onToggleVisibility;

  const AuthLabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.obscure = false,
    this.iconColor = Colors.black45,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && obscure,
          keyboardType: isPassword ? null : keyboardType,
          style: AppTheme.cuerpo,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.black45),
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: onToggleVisibility,
                    child: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: iconColor,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
