import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/supabase_client.dart';
import 'editar_cliente_view.dart';

class ClienteDetalleView extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final Map<String, dynamic> usuario;

  const ClienteDetalleView({
    Key? key,
    required this.cliente,
    required this.usuario,
  }) : super(key: key);

  @override
  State<ClienteDetalleView> createState() => _ClienteDetalleViewState();
}

class _ClienteDetalleViewState extends State<ClienteDetalleView> {
  Map<int, double> pagosPorCuota = {};
  Map<int, String> fechaCuota = {};
  bool cargando = true;

  static const Color azulBase = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    cargarPagos();
  }

  Future<void> cargarPagos() async {
    final data = await supabase
        .from('pagos')
        .select('numero_cuota, monto, fecha')
        .eq('cliente_id', widget.cliente['id']);

    pagosPorCuota.clear();
    fechaCuota.clear();

    for (final p in data) {
      final cuota = p['numero_cuota'];
      final monto = double.parse(p['monto'].toString());
      pagosPorCuota[cuota] = (pagosPorCuota[cuota] ?? 0) + monto;
      fechaCuota[cuota] = p['fecha'];
    }

    setState(() => cargando = false);
  }

  bool cuotasAnterioresCompletas(int cuotaActual) {
    final valorCuota = widget.cliente['valor_cuota'];
    for (int i = 1; i < cuotaActual; i++) {
      if ((pagosPorCuota[i] ?? 0) < valorCuota) return false;
    }
    return true;
  }

  int? ultimaCuotaPagada() {
    final valorCuota = widget.cliente['valor_cuota'];
    final total = widget.cliente['numero_cuotas'];
    for (int i = total; i >= 1; i--) {
      if ((pagosPorCuota[i] ?? 0) >= valorCuota) return i;
    }
    return null;
  }

  String fechaHoy() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  Future<void> mostrarCuota(int cuota) async {
    final rol = widget.usuario['rol'];
    final valorCuota = widget.cliente['valor_cuota'];
    final pagado = pagosPorCuota[cuota] ?? 0;
    final completa = pagado >= valorCuota;
    final fecha = completa ? fechaCuota[cuota] : fechaHoy();
    final ultima = ultimaCuotaPagada();

    if (!completa && !cuotasAnterioresCompletas(cuota)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes pagar primero las cuotas anteriores'),
        ),
      );
      return;
    }

    final accion = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Cuota $cuota'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Valor cuota: \$ ${formatoCOP(valorCuota)}'),
                const SizedBox(height: 8),
                Text('Fecha: $fecha'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cerrar'),
                child: const Text('Cerrar'),
              ),
              if (!completa)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'pagar'),
                  child: const Text('Registrar pago'),
                ),
              if (completa && cuota == ultima && rol == 'admin')
                TextButton(
                  onPressed: () => Navigator.pop(context, 'deshacer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Deshacer pago'),
                ),
            ],
          ),
    );

    if (accion == 'pagar') {
      await supabase.from('pagos').insert({
        'cliente_id': widget.cliente['id'],
        'numero_cuota': cuota,
        'monto': valorCuota - pagado,
        'fecha': fechaHoy(),
        'ruta': widget.cliente['ruta'],
      });
    }

    if (accion == 'deshacer') {
      await supabase
          .from('pagos')
          .delete()
          .eq('cliente_id', widget.cliente['id'])
          .eq('numero_cuota', cuota);
    }

    if (accion != null) cargarPagos();
  }

  Future<void> mostrarRecarga() async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Recarga'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                copFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (ok != true || ctrl.text.isEmpty) return;

    final montoBase = double.parse(ctrl.text.replaceAll('.', ''));
    final montoFinal = montoBase * 1.2;
    final cuotas = widget.cliente['numero_cuotas'];
    final valorCuota = montoFinal / cuotas;

    await supabase
        .from('pagos')
        .delete()
        .eq('cliente_id', widget.cliente['id']);

    await supabase
        .from('clientes')
        .update({'monto': montoFinal, 'valor_cuota': valorCuota})
        .eq('id', widget.cliente['id']);

    cargarPagos();
  }

  String formatoCOP(dynamic value) {
    final n = value.toString().split('.').first;
    return n.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  TextInputFormatter copFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final limpio = newValue.text.replaceAll('.', '');
      if (limpio.isEmpty) return newValue.copyWith(text: '');
      final f = formatoCOP(limpio);
      return TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: f.length),
      );
    });
  }

  Widget item(String t, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rol = widget.usuario['rol'];
    final totalCuotas = widget.cliente['numero_cuotas'];
    final valorCuota = widget.cliente['valor_cuota'];
    final totalPagado = pagosPorCuota.values.fold<double>(0, (a, b) => a + b);
    final saldo = widget.cliente['monto'] - totalPagado;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulBase,
        foregroundColor: Colors.white,
        title: const Text('Detalle del cliente'),
        actions: [
          if (rol == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditarClienteView(cliente: widget.cliente),
                  ),
                );
                if (r == true) Navigator.pop(context, true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await supabase
                    .from('clientes')
                    .delete()
                    .eq('id', widget.cliente['id']);
                Navigator.pop(context, true);
              },
            ),
          ],
        ],
      ),
      body:
          cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    Text(
                      widget.cliente['nombre'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    item('Dirección', widget.cliente['direccion'] ?? '-'),
                    item('Teléfono', widget.cliente['telefono'] ?? '-'),
                    item('Referencia 1', widget.cliente['referencia_1'] ?? '-'),
                    item('Referencia 2', widget.cliente['referencia_2'] ?? '-'),

                    const Divider(height: 30),

                    item(
                      'Monto total',
                      '\$ ${formatoCOP(widget.cliente['monto'])}',
                    ),
                    item('Valor cuota', '\$ ${formatoCOP(valorCuota)}'),
                    item('Número de cuotas', totalCuotas.toString()),
                    item('Tipo de cliente', widget.cliente['tipo_cliente']),
                    item('Fecha', widget.cliente['fecha'] ?? '-'),
                    item('Saldo restante', '\$ ${formatoCOP(saldo)}'),

                    const SizedBox(height: 30),

                    const Text(
                      'Cuotas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: totalCuotas,
                      itemBuilder: (_, i) {
                        final n = i + 1;
                        final pagado = pagosPorCuota[n] ?? 0;

                        Color color;
                        if (pagado == 0) {
                          color = Colors.grey.shade300;
                        } else if (pagado < valorCuota) {
                          color = Colors.orange;
                        } else {
                          color = Colors.green;
                        }

                        return GestureDetector(
                          onTap: () => mostrarCuota(n),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              n.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    if (rol == 'admin')
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: mostrarRecarga,
                          child: const Text('RECARGA'),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
