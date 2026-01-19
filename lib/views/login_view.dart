import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final usuarioController = TextEditingController();
  final passwordController = TextEditingController();
  bool cargando = false;

  Future<void> iniciarSesion() async {
    setState(() => cargando = true);

    try {
      final data = await AuthService.login(
        usuario: usuarioController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (data == null) {
        throw 'Credenciales incorrectas';
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeView(usuario: data)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulBase = Color(0xFF1565C0);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: azulBase),
            const SizedBox(height: 24),

            TextField(
              controller: usuarioController,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: azulBase),
                onPressed: cargando ? null : iniciarSesion,
                child:
                    cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
