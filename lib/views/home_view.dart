import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import 'ruta_opciones_view.dart';
import 'login_view.dart';

class HomeView extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const HomeView({Key? key, required this.usuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const azulBase = Color(0xFF1565C0);
    final List<int> rutas = List<int>.from(usuario['rutas']);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulBase,
        foregroundColor: Colors.white,
        title: Text('Bienvenido ${usuario['nombre']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children:
              rutas.map((ruta) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RutaOpcionesView(
                              rutaNombre: 'Ruta $ruta',
                              usuario: usuario,
                            ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    child: Center(
                      child: Text(
                        'Ruta $ruta',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
