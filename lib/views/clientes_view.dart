import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import 'crear_cliente_view.dart';
import 'cliente_detalle_view.dart';

class ClientesView extends StatefulWidget {
  final String rutaNombre;
  final Map<String, dynamic> usuario;

  const ClientesView({
    Key? key,
    required this.rutaNombre,
    required this.usuario,
  }) : super(key: key);

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  List<dynamic> clientes = [];
  List<dynamic> clientesFiltrados = [];
  bool cargando = true;

  String busqueda = '';
  String filtroTipo = 'Todos';

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    final data = await supabase
        .from('clientes')
        .select()
        .eq('ruta', widget.rutaNombre)
        .order('created_at', ascending: false);

    clientes = data;
    aplicarFiltros();
    setState(() => cargando = false);
  }

  void aplicarFiltros() {
    clientesFiltrados =
        clientes.where((c) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final telefono = (c['telefono'] ?? '').toString().toLowerCase();
          final tipo = (c['tipo_cliente'] ?? '').toString();

          final coincideBusqueda =
              busqueda.isEmpty ||
              nombre.contains(busqueda) ||
              telefono.contains(busqueda);

          final coincideTipo = filtroTipo == 'Todos' || tipo == filtroTipo;

          return coincideBusqueda && coincideTipo;
        }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const azulBase = Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulBase,
        foregroundColor: Colors.white,
        title: Text('Clientes - ${widget.rutaNombre}'),
      ),
      body:
          cargando
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 🔍 BUSCADOR
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o teléfono',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        busqueda = v.toLowerCase();
                        aplicarFiltros();
                      },
                    ),
                  ),

                  // 🎯 FILTRO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<String>(
                      value: filtroTipo,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por tipo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'Semanal',
                          child: Text('Semanal'),
                        ),
                        DropdownMenuItem(
                          value: 'Quincenal',
                          child: Text('Quincenal'),
                        ),
                        DropdownMenuItem(
                          value: 'Mensual',
                          child: Text('Mensual'),
                        ),
                      ],
                      onChanged: (v) {
                        filtroTipo = v!;
                        aplicarFiltros();
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 📋 LISTA
                  Expanded(
                    child:
                        clientesFiltrados.isEmpty
                            ? const Center(child: Text('No hay clientes'))
                            : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: clientesFiltrados.length,
                              itemBuilder: (context, index) {
                                final c = clientesFiltrados[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(c['nombre']),
                                    subtitle: Text(
                                      'Tel: ${c['telefono']} • ${c['tipo_cliente']}',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () async {
                                      final actualizado = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ClienteDetalleView(
                                                cliente: c,
                                                usuario: widget.usuario,
                                              ),
                                        ),
                                      );

                                      if (actualizado == true) {
                                        cargarClientes();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),

      // ➕ TODOS PUEDEN CREAR
      floatingActionButton: FloatingActionButton(
        backgroundColor: azulBase,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final creado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CrearClienteView(rutaNombre: widget.rutaNombre),
            ),
          );

          if (creado == true) {
            cargarClientes();
          }
        },
      ),
    );
  }
}
