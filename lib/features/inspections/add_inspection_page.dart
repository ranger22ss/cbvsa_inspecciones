import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';
import '../../core/providers.dart';
import 'modules_evaluation_page.dart';

class AddInspectionPage extends ConsumerStatefulWidget {
  const AddInspectionPage({super.key});

  @override
  ConsumerState<AddInspectionPage> createState() => _AddInspectionPageState();
}

class _AddInspectionPageState extends ConsumerState<AddInspectionPage> {
  final _formKey = GlobalKey<FormState>();

  final _radicadoCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _nombreComCtrl = TextEditingController();
  final _representanteCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _acompananteCtrl = TextEditingController();

  bool _subsanadasPrevias = false;
  bool _emergenciasUltimoAnio = false;
  String _tipoInspeccion = 'comercio_pequeno';

  final _picker = ImagePicker();
  File? _fotoFachadaFile;
  String? _fotoFachadaUrl;

  Future<void> _pickFotoFachada() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _fotoFachadaFile = File(picked.path);
    });

    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser!;
    final storage = StorageService(supabase);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subiendo foto de fachada...')),
    );

    try {
      final url = await storage.uploadImage(
        file: File(picked.path),
        userId: user.id,
        questionId: 'fachada',
      );
      setState(() => _fotoFachadaUrl = url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de fachada subida ✔')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir foto: $e')),
      );
    }
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoFachadaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tomar la foto de fachada')),
      );
      return;
    }

    final baseData = {
      'radicado': _radicadoCtrl.text,
      'fecha_inspeccion': _fechaCtrl.text,
      'nombre_comercial': _nombreComCtrl.text,
      'representante_legal': _representanteCtrl.text,
      'direccion_rut': _direccionCtrl.text,
      'celular_rut': _celularCtrl.text,
      'acompanante': _acompananteCtrl.text,
      'foto_fachada_url': _fotoFachadaUrl,
      'visita_anterior': {
        'subsanadas_obs_previas': _subsanadasPrevias,
        'emergencias_ultimo_anio': _emergenciasUltimoAnio,
      },
    };

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ModulesEvaluationPage(
        baseData: baseData,
        tipoInspeccion: _tipoInspeccion,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoja 1 – Crear Inspección')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _radicadoCtrl,
              decoration: const InputDecoration(labelText: 'Radicado'),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _fechaCtrl,
              decoration: const InputDecoration(labelText: 'Fecha de inspección (AAAA-MM-DD)'),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _nombreComCtrl,
              decoration: const InputDecoration(labelText: 'Nombre comercial'),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _representanteCtrl,
              decoration: const InputDecoration(labelText: 'Representante legal'),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _direccionCtrl,
              decoration: const InputDecoration(labelText: 'Dirección'),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            TextFormField(
              controller: _celularCtrl,
              decoration: const InputDecoration(labelText: 'Celular (10 dígitos)'),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                if (v.length != 10) return 'Debe tener 10 dígitos';
                return null;
              },
            ),
            TextFormField(
              controller: _acompananteCtrl,
              decoration: const InputDecoration(labelText: 'Acompañante'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tipoInspeccion,
              items: const [
                DropdownMenuItem(value: 'comercio_pequeno', child: Text('Comercio pequeño')),
                DropdownMenuItem(value: 'comercio_grande', child: Text('Comercio grande')),
                DropdownMenuItem(value: 'estacion_servicio', child: Text('Estación de servicio')),
                DropdownMenuItem(value: 'industria', child: Text('Industria')),
              ],
              onChanged: (v) => setState(() => _tipoInspeccion = v ?? 'comercio_pequeno'),
              decoration: const InputDecoration(labelText: 'Tipo de inspección'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFotoFachada,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Tomar foto fachada'),
            ),
            if (_fotoFachadaFile != null) ...[
              const SizedBox(height: 8),
              Image.file(_fotoFachadaFile!, height: 120),
            ],
            const Divider(),
            SwitchListTile(
              value: _subsanadasPrevias,
              onChanged: (v) => setState(() => _subsanadasPrevias = v),
              title: const Text('¿Se subsanaron observaciones de inspección anterior?'),
            ),
            SwitchListTile(
              value: _emergenciasUltimoAnio,
              onChanged: (v) => setState(() => _emergenciasUltimoAnio = v),
              title: const Text('¿Hubo emergencias en el último año?'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _continuar,
              child: const Text('Continuar evaluación →'),
            ),
          ],
        ),
      ),
    );
  }
}
