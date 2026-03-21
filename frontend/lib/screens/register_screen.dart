import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenScreenState();
}

class _RegisterScreenScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _passwd = TextEditingController();
  final _user = TextEditingController();

  bool _obscure = true; 
  bool _loading = false;
  String? _error;
  final _auth = AuthService();



  @override
  void dispose() {
    _email.dispose();
    _passwd.dispose();
    _user.dispose();
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
                  'Crear cuenta',
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
                  // USUARIO
                  _buildLabel('Usuario'),
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
                  _buildLabel('Email'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTheme.cuerpo,
                    decoration: const InputDecoration(
                      hintText: 'correo@ejemplo.com',
                      prefixIcon: Icon(
                        Icons.mail_outline,
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
                  if(_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color:AppTheme.usal, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                  ],

                  // BOTÓN PRINCIPAL
                  ElevatedButton(

                    onPressed: _loading ? null : _register,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.usal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: AppTheme.cuerpo.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text ('Crear cuenta'),
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

  Future<void> _register() async{
    if(_email.text.isEmpty || _passwd.text.isEmpty || _user.text.isEmpty){
      setState(() => _error = 'Rellena todos los campos');
      return;
    }

    if(_passwd.text.length < 8){
      setState(() => _error = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try{
      await _auth.createAccount(email: _email.text.trim(), passwd: _passwd.text.trim());
      await _auth.updateUsername(username: _user.text.trim());
      
      if(!mounted){
        return;
      }

      context.go('/home');
    } catch (e){
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }

  }

}
