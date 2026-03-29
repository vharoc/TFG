import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/chat_input.dart';
import '../widgets/hamburger_btt.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          HamburgerButton(
            onTap: () {
              print('Hamburger pressed');
            },
          ),

          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bienvenido a',
                        style: AppTheme.titulo.copyWith(fontSize: 24),
                      ),
                      Text(
                        'TourClick',
                        style: AppTheme.titulo.copyWith(
                          fontSize: 32,
                          color: AppTheme.usal,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ChatInput(
                onSend: (text) {
                  print(text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}