import 'package:flutter/material.dart';
import '../theme/theme.dart';


class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {

    final _email = TextEditingController();
    final _passwd = TextEditingController();
    bool _obscure = true;

    @override
    void dispose() {
        _email.dispose();
        _passwd.dispose();
        super.dispose();
    }


    @override
    Widget build(BuildContext context){
        return Scaffold(
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            
                            const Spacer(),

                            // LOGO
                            Image.asset(
                                'assets/images/logo.png',
                                height: 80,
                            ),

                            const SizedBox(height: 80),


                            // EMAIL
                            TextField(
                                controller: _email,
                                style: AppTheme.cuerpo,
                                decoration: const InputDecoration(
                                    hintText: 'Email o usuario',
                                    border: 
                                ),
                            ),

                            const SizedBox(height: 12),

                            // CONTRASEÑA
                            TextField(
                                controller: _passwd,
                                obscureText: _obscure,
                                style: AppTheme.cuerpo,
                                decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    suffixIcon: GestureDetector(
                                        onTap: () => setState(() => _obscure = !_obscure),
                                        child: Icon(
                                            _obscure ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.black,
                                        ),
                                    ),
                                ),    
                            ),

                            const SizedBox(height: 24),


                            // Botón LOGIN
                            ElevatedButton(
                                onPressed: () {
                                    // TODO : logica login
                                },

                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.usal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: AppTheme.cuerpo.copyWith(fontWeight: FontWeight.bold),
                                    // side: const BorderSide(color: Colors.black, width: 1),
                                ),

                                child: const Text('Iniciar sesión'),
                            ),

                            const Spacer(),
                            OutlinedButton(
                                onPressed: () {
                                    // TODO: navegar a RegisterScreen
                                },
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.usal,
                                    backgroundColor: AppTheme.fondo,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: AppTheme.usal, width: 2),
                                    textStyle: AppTheme.cuerpo.copyWith(fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Crear cuenta nueva'),
                                ),

                            // texto a registro
                            

                            const SizedBox(height: 24),

                        ],
                    ),
                ),
            ),
        );
    }

}