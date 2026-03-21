import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrUser = TextEditingController();
  final _passwd = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailOrUser.dispose();
    _passwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER CON LOGO
          Container(
            color: AppTheme.usal,
            padding: const EdgeInsets.only(top: 64, bottom: 32),
            child: Column(
              children: [
                Image.asset('assets/images/logo_only.png', height: 72),
                const SizedBox(height: 12),
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // FORMULARIO
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // EMAIL
                  _buildLabel('Email o usuario'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailOrUser,
                    style: AppTheme.cuerpo,
                    decoration: const InputDecoration(
                      hintText: 'Introduce tu email o usuario',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.black45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CONTRASEÑA
                  _buildLabel('Contraseña'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwd,
                    obscureText: _obscure,
                    style: AppTheme.cuerpo,
                    decoration: InputDecoration(
                      hintText: 'Introduce tu contraseña',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.black45,
                      ),

                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // BOTON PRINCIPAL
                  ElevatedButton(
                    onPressed: () {
                      // TODO : logica login
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.usal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: AppTheme.cuerpo.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Iniciar sesión'),
                  ),

                  const SizedBox(height: 24),

                  // SEPARADOR
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o',
                          style: TextStyle(color: Colors.black45),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ENLACE A REGISTRO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Crear cuenta',
                          style: TextStyle(
                            color: AppTheme.usal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTheme.cuerpo.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.6,
        color: Colors.black54,
      ),
    );
  }
}
