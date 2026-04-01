import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/theme.dart';
import '../services/auth_services.dart';
import '../widgets/header_logo.dart';
import '../widgets/separator.dart';
import '../widgets/form_lbl.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _passwd = TextEditingController();
  
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  final _auth = AuthService();

  @override
  void dispose() {
    _email.dispose();
    _passwd.dispose();
    super.dispose();
  }

  String _parseError(dynamic e){
    if (e is FirebaseAuthException){
      return switch (e.code){
        "user-not-found" => 'No existe usuario asociado al correo',
        'wrong-password' => 'Contraseña incorrecta',
        'invalid-email' => 'Formato de email no válido',
        'invalid-credential' => 'Email o contraseña incorrectos',
        'too-many-requests'     => 'Demasiados intentos, espera unos minutos',
        _                       => 'Error inesperado, inténtalo de nuevo',
      };
    }
    return 'Error, inténtalo de nuevo';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER CON LOGO
          const HeaderLogo(title: 'Iniciar sesión'),

          // FORMULARIO
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // EMAIL
                  const FormLabel('Email o usuario'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _email,
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
                  const FormLabel('Contraseña'),
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

                  if(_error != null) ... [
                    Text(
                      _error!,
                      style: TextStyle(color:AppTheme.usal, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                  ],

                  // BOTON PRINCIPAL
                  ElevatedButton(

                    onPressed: _loading ? null : _login,

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
                  const Separator(),

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

  Future<void> _login() async {
    if(_email.text.isEmpty || _passwd.text.isEmpty){
      setState(() => _error = 'Rellena todos los campos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try{
      await _auth.signIn(email:_email.text.trim(), passwd: _passwd.text.trim());
      if(!mounted){
        return;
      }
      context.go('/home');
    } catch (e){
      setState(() => _error = _parseError(e));
    } finally {
      setState(() => _loading = false);
    }

  }


}
