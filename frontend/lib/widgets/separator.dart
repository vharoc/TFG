import 'package:flutter/material.dart';


class Separator extends StatelessWidget {
  final String label;
 
  const Separator({super.key, this.label = 'o'});
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(color: Colors.black45),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
