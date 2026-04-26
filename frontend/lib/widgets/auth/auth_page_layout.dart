import 'package:flutter/material.dart';

import '../common/header_logo.dart';

class AuthPageLayout extends StatelessWidget {
  final String title;
  final Widget child;

  const AuthPageLayout({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderLogo(title: title),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
