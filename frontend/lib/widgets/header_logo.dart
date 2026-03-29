import 'package:flutter/material.dart';
import '../theme/theme.dart';

class HeaderLogo extends StatelessWidget{

  final String title;

  const HeaderLogo({super.key, required this.title});

  @override
  Widget build(BuildContext context){
    return Container(
      color: AppTheme.usal,
      padding: const EdgeInsets.only(top: 64, bottom: 32),
      child: Column(
        children: [
          Image.asset('assets/images/logo_only.png', height: 72),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }



}