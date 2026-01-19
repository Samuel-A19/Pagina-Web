import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/supabase_client.dart';

class CrearClienteView extends StatefulWidget {
  final String rutaNombre;

  const CrearClienteView({Key? key, required this.rutaNombre})
    : super(key: key);

  @override
  State<CrearClienteView> createState() => _CrearClienteViewState();
}

class _CrearClienteViewState extends State<CrearClienteView> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final direccionController = TextEditingController();
  final telefonoController = TextEditingController();
  final ref1Controller = TextEditingController();
  final ref2Controller = TextEditingController();
  final montoController = TextEditingController();
  final fechaController = TextEditingController();
  final cuotasController = TextEditingController();

  String tipoCliente = 'Semanal';
  bool guardando = false;

  String formatoCOP(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) return '';
    return value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    try {
      // MONTO BASE
      final montoBase = double.parse(montoController.text.replaceAll('.', ''));

      // +20%
      final montoConInteres = montoBase * 1.2;

      // CUOTAS
      final cuotas = int.parse(cuotasController.text);

      // VALOR CUOTA
      final valorCuota = montoConInteres / cuotas;

      await supabase.from('clientes').insert({
        'ruta': widget.rutaNombre,
        'nombre': nombreController.text.trim(),
        'direccion': direccionController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'referencia_1': ref1Controller.text.trim(),
        'referencia_2': ref2Controller.text.trim(),
        'monto': montoConInteres,
        'numero_cuotas': cuotas,
        'valor_cuota': valorCuota,
        'tipo_cliente': tipoCliente,
        'fecha': fechaController.text.trim(),
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulBase = Color(0xFF1565C0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: azulBase,
        foregroundColor: Colors.white,
        title: const Text('Crear Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator:
                    (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ref1Controller,
                decoration: const InputDecoration(labelText: 'Referencia 1'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ref2Controller,
                decoration: const InputDecoration(labelText: 'Referencia 2'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: montoController,
                decoration: const InputDecoration(labelText: 'Monto (COP)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final f = formatoCOP(value);
                  montoController.value = TextEditingValue(
                    text: f,
                    selection: TextSelection.collapsed(offset: f.length),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cuotasController,
                decoration: const InputDecoration(
                  labelText: 'Número de cuotas',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator:
                    (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipoCliente,
                decoration: const InputDecoration(labelText: 'Tipo de cliente'),
                items: const [
                  DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                  DropdownMenuItem(
                    value: 'Quincenal',
                    child: Text('Quincenal'),
                  ),
                  DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                ],
                onChanged: (v) => setState(() => tipoCliente = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha (dd/mm/aaaa)',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: azulBase),
                  onPressed: guardando ? null : guardarCliente,
                  child:
                      guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'CREAR CLIENTE',
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
      ),
    );
  }
}
