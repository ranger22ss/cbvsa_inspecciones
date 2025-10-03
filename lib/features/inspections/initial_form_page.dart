import 'dart:io';
import 'package:cbvsa_inspecciones/features/inspections/evaluation_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// --- Safe dropdown widget (pegado aquí para no tocar más archivos) ---
class SafeDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final FormFieldValidator<T?>? validator;
  final bool autovalidateMode;

  const SafeDropdownFormField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.decoration,
    this.validator,
    this.autovalidateMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Deduplicar items por value (mantener el primero)
    final Map<dynamic, DropdownMenuItem<T>> map = {};
    for (final it in items) {
      map.putIfAbsent(it.value, () => it);
    }
    final uniqueItems = map.values.toList();

    // Si el value no está exactamente 1 vez -> lo anulamos para evitar assert
    T? safeValue = value;
    if (safeValue != null) {
      final found = uniqueItems.where((e) => e.value == safeValue).length;
      if (found != 1) {
        // Log para diagnóstico
        // ignore: avoid_print
        print(
            'SafeDropdownFormField: value="$safeValue" not found exactly once in items (found=$found). Forcing null to avoid crash. Items: ${uniqueItems.map((e) => e.value).toList()}');
        safeValue = null;
      }
    }

    return DropdownButtonFormField<T>(
      value: safeValue,
      items: uniqueItems,
      onChanged: onChanged,
      decoration: decoration,
      validator: validator,
    );
  }
}
// --- end SafeDropdownFormField ---

class InitialFormPage extends StatefulWidget {
  const InitialFormPage({super.key});

  @override
  State<InitialFormPage> createState() => _InitialFormPageState();
}

class _InitialFormPageState extends State<InitialFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreComercialCtrl = TextEditingController();
  final _representanteCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _acompananteCtrl = TextEditingController();

  DateTime? _fechaInspeccion;
  File? _fotoFachada;
  String? _selectedTipo;

  static const List<String> _tiposBase = <String>[
    'comercio_pequeno',
    'comercio_grande',
    'estacion_servicio',
    'industria',
  ];

  String _labelTipo(String v) {
    switch (v) {
      case 'comercio_pequeno':
        return 'Comercio pequeño';
      case 'comercio_grande':
        return 'Comercio grande';
      case 'estacion_servicio':
        return 'Estación de servicio';
      case 'industria':
        return 'Industria';
      default:
        return v;
    }
  }

  @override
  void dispose() {
    _nombreComercialCtrl.dispose();
    _representanteCtrl.dispose();
    _direccionCtrl.dispose();
    _celularCtrl.dispose();
    _acompananteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _fechaInspeccion = picked);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => _fotoFachada = File(picked.path));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Faltan campos obligatorios')));
      return;
    }
    if (_fechaInspeccion == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seleccione la fecha de inspección')));
      return;
    }
    if (_fotoFachada == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Agregue la foto de fachada')));
      return;
    }
    if (_selectedTipo == null || !_tiposBase.contains(_selectedTipo)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seleccione el tipo de inspección')));
      return;
    }

    final data = {
      'fecha_inspeccion': _fechaInspeccion!.toIso8601String(),
      'nombre_comercial': _nombreComercialCtrl.text.trim(),
      'representante_legal': _representanteCtrl.text.trim(),
      'direccion_rut': _direccionCtrl.text.trim(),
      'celular_rut': _celularCtrl.text.trim(),
      'acompanante': _acompananteCtrl.text.trim(),
      'foto_fachada': _fotoFachada!.path,
      'tipo_inspeccion': _selectedTipo,
    };

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EvaluationPage(initialData: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipos = _tiposBase.toSet().toList();
    final items = tipos
        .map((v) => DropdownMenuItem<String>(value: v, child: Text(_labelTipo(v))))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Hoja 1 - Datos Iniciales')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreComercialCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre comercial',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _representanteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Representante legal',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _celularCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Celular (10 dígitos)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (v.trim().length != 10) return 'Debe tener 10 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _acompananteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Acompañante',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Fecha
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fechaInspeccion == null
                          ? 'Seleccione fecha'
                          : 'Fecha: ${_fechaInspeccion!.day}/${_fechaInspeccion!.month}/${_fechaInspeccion!.year}',
                    ),
                  ),
                  IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
                ],
              ),
              const SizedBox(height: 12),

              // Foto fachada
              Row(
                children: [
                  Expanded(
                    child: _fotoFachada == null
                        ? const Text('Sin foto de fachada')
                        : Image.file(_fotoFachada!, height: 100),
                  ),
                  IconButton(onPressed: _pickPhoto, icon: const Icon(Icons.camera_alt)),
                ],
              ),
              const SizedBox(height: 12),

              // Dropdown seguro
              SafeDropdownFormField<String>(
                value: _selectedTipo,
                items: items,
                onChanged: (v) => setState(() => _selectedTipo = v),
                decoration: const InputDecoration(
                  labelText: 'Tipo de inspección',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Seleccione un tipo' : null,
              ),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar evaluación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
