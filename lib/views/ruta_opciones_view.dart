import 'package:flutter/material.dart';
import 'clientes_view.dart';

class RutaOpcionesView extends StatelessWidget {
  final String rutaNombre;
  final Map<String, dynamic> usuario;

  const RutaOpcionesView({
    Key? key,
    required this.rutaNombre,
    required this.usuario,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const azulBase = Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulBase,
        foregroundColor: Colors.white,
        title: Text(rutaNombre),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            // CLIENTES (TODOS)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ClientesView(
                          rutaNombre: rutaNombre,
                          usuario: usuario,
                        ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: const Center(
                  child: Text(
                    'Clientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            // CUENTAS (TODOS)
            Card(
              elevation: 4,
              child: const Center(
                child: Text(
                  'Cuentas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
