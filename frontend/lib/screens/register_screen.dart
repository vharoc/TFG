import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../widgets/form_lbl.dart';
import '../widgets/separator.dart';
import '../widgets/header_logo.dart';
import '../viewmodels/register_view_model.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _passwd = TextEditingController();
  final _user = TextEditingController();
  
  bool _obscure = true; 
  final _vm = RegisterViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _passwd.dispose();
    _user.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final ok = await _vm.register(
      email: _email.text.trim(),
      passwd: _passwd.text.trim(),
      nombre: _user.text.trim(),
    );
 
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER CON LOGO
          const HeaderLogo(title: 'Crear cuenta'),

          // FORMULARIO
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // USUARIO
                  const FormLabel('Usuario'),

                  const SizedBox(height: 6),
                  TextField(
                    controller: _user,
                    style: AppTheme.cuerpo,
                    decoration: const InputDecoration(
                      hintText: 'Elige un nombre de usuario',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.black45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // EMAIL
                  const FormLabel('Email'),

                  const SizedBox(height: 6),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTheme.cuerpo,
                    decoration: const InputDecoration(
                      hintText: 'correo@ejemplo.com',
                      prefixIcon: Icon(Icons.mail_outline,color: Colors.black45),
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
                      hintText: 'Mínimo 8 caracteres',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.black45,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ERROR 
                  if (_vm.error != null) ...[
                    Text(
                      _vm.error!,
                      style: TextStyle(color: AppTheme.usal, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // BOTÓN PRINCIPAL
                  ElevatedButton(

                    onPressed: _vm.loading ? null : _register,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.usal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: AppTheme.cuerpo.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _vm.loading ? const CircularProgressIndicator(color: Colors.white) : const Text ('Crear cuenta'),
                  ),

                  const SizedBox(height: 24),

                  const Separator(),

                  const SizedBox(height: 16),

                  // ENLACE A LOGIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text(
                        '¿Ya tienes cuenta?',
                        style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Iniciar sesión',
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
}
