import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/supabase_client.dart';

class EditarClienteView extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const EditarClienteView({Key? key, required this.cliente}) : super(key: key);

  @override
  State<EditarClienteView> createState() => _EditarClienteViewState();
}

class _EditarClienteViewState extends State<EditarClienteView> {
  late TextEditingController nombreCtrl;
  late TextEditingController direccionCtrl;
  late TextEditingController telefonoCtrl;
  late TextEditingController ref1Ctrl;
  late TextEditingController ref2Ctrl;
  late TextEditingController montoCtrl;
  late TextEditingController cuotasCtrl;
  late TextEditingController fechaCtrl;

  late double montoBaseOriginal;

  String tipoCliente = 'Semanal';
  bool guardando = false;

  static const Color azulBase = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();

    // 🔹 monto base SIN interés
    montoBaseOriginal = (widget.cliente['monto'] / 1.2).roundToDouble();

    nombreCtrl = TextEditingController(text: widget.cliente['nombre'] ?? '');
    direccionCtrl = TextEditingController(
      text: widget.cliente['direccion'] ?? '',
    );
    telefonoCtrl = TextEditingController(
      text: widget.cliente['telefono'] ?? '',
    );
    ref1Ctrl = TextEditingController(
      text: widget.cliente['referencia_1'] ?? '',
    );
    ref2Ctrl = TextEditingController(
      text: widget.cliente['referencia_2'] ?? '',
    );

    montoCtrl = TextEditingController(text: formatoCOP(montoBaseOriginal));

    cuotasCtrl = TextEditingController(
      text: widget.cliente['numero_cuotas'].toString(),
    );

    fechaCtrl = TextEditingController(text: widget.cliente['fecha'] ?? '');

    tipoCliente = widget.cliente['tipo_cliente'] ?? 'Semanal';
  }

  Future<void> guardarCambios() async {
    setState(() => guardando = true);

    try {
      final montoBaseNuevo = double.parse(montoCtrl.text.replaceAll('.', ''));
      final cuotas = int.parse(cuotasCtrl.text);

      if (cuotas <= 0) {
        throw 'El número de cuotas debe ser mayor a 0';
      }

      // 🔥 aplicar 20 %
      final montoConInteres = montoBaseNuevo * 1.2;
      final valorCuota = montoConInteres / cuotas;

      final montoModificado = montoBaseNuevo != montoBaseOriginal;

      // 1️⃣ actualizar cliente
      await supabase
          .from('clientes')
          .update({
            'nombre': nombreCtrl.text.trim(),
            'direccion': direccionCtrl.text.trim(),
            'telefono': telefonoCtrl.text.trim(),
            'referencia_1': ref1Ctrl.text.trim(),
            'referencia_2': ref2Ctrl.text.trim(),
            'monto': montoConInteres,
            'numero_cuotas': cuotas,
            'valor_cuota': valorCuota,
            'tipo_cliente': tipoCliente,
            'fecha': fechaCtrl.text.trim(),
          })
          .eq('id', widget.cliente['id']);

      // 2️⃣ SOLO si cambia el monto → reiniciar pagos
      if (montoModificado) {
        await supabase
            .from('pagos')
            .delete()
            .eq('cliente_id', widget.cliente['id']);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => guardando = false);
    }
  }

  // ---------- FORMATOS ----------

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
      final formateado = formatoCOP(limpio);
      return TextEditingValue(
        text: formateado,
        selection: TextSelection.collapsed(offset: formateado.length),
      );
    });
  }

  // ---------- CAMPO ----------

  Widget campo(
    String label,
    TextEditingController controller, {
    TextInputType tipo = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: tipo,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label, // ✅ error corregido
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulBase,
        foregroundColor: Colors.white,
        title: const Text('Editar cliente'),
      ),
      body:
          guardando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    campo('Nombre completo', nombreCtrl),
                    campo('Dirección', direccionCtrl),
                    campo(
                      'Teléfono',
                      telefonoCtrl,
                      tipo: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    campo('Referencia 1', ref1Ctrl),
                    campo('Referencia 2', ref2Ctrl),

                    campo(
                      'Monto',
                      montoCtrl,
                      tipo: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        copFormatter(),
                      ],
                    ),

                    campo(
                      'Número de cuotas',
                      cuotasCtrl,
                      tipo: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    DropdownButtonFormField<String>(
                      value: tipoCliente,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de cliente',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
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
                      onChanged: (v) => setState(() => tipoCliente = v!),
                    ),

                    const SizedBox(height: 14),

                    campo('Fecha', fechaCtrl),

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulBase,
                        ),
                        onPressed: guardarCambios,
                        child: const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
