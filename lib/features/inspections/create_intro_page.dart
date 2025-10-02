import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import '../../core/storage.dart';
import '../../core/templates.dart';
import 'new_inspection_wizard.dart';

class CreateInspectionIntroPage extends ConsumerStatefulWidget {
  const CreateInspectionIntroPage({super.key});

  @override
  ConsumerState<CreateInspectionIntroPage> createState() => _CreateInspectionIntroPageState();
}

class _CreateInspectionIntroPageState extends ConsumerState<CreateInspectionIntroPage> {
  final _formKey = GlobalKey<FormState>();

  final _radicadoCtrl = TextEditingController();
  DateTime? _fecha;
  final _nombreComCtrl = TextEditingController();
  final _repLegalCtrl = TextEditingController();
  final _dirRutCtrl = TextEditingController();
  final _celularRutCtrl = TextEditingController();
  final _acompananteCtrl = TextEditingController();

  String _tipoInspeccion = 'comercio_pequeno'; // default
  bool? _subsanadasPrevias;  // requerido (sí/no)
  bool? _emergenciasUltAnio; // requerido (sí/no)

  String? _fotoFachadaUrl;

  final _picker = ImagePicker();
  bool _saving = false;

  @override
  void dispose() {
    _radicadoCtrl.dispose();
    _nombreComCtrl.dispose();
    _repLegalCtrl.dispose();
    _dirRutCtrl.dispose();
    _celularRutCtrl.dispose();
    _acompananteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFachada() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser!;
    final storage = StorageService(supabase);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo fachada...')));

    try {
      final file = File(picked.path);
      // guardamos en <uid>/fachada/<uuid>.jpg
      final url = await storage.uploadImage(
        file: file,
        userId: user.id,
        questionId: 'fachada',
      );
      if (!mounted) return;
      setState(() => _fotoFachadaUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fachada subida ✔')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error subiendo fachada: $e')));
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _continuar() async {
    if (_fecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona la fecha')));
      return;
    }
    if (_subsanadasPrevias == null || _emergenciasUltAnio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responde visita anterior')));
      return;
    }
    if (_fotoFachadaUrl == null || _fotoFachadaUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adjunta la foto de fachada')));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser!;
      final inspectorProfile = await supabase
          .from('profiles')
          .select('full_name, national_id, role')
          .eq('id', user.id)
          .maybeSingle();

      final inspectorJson = {
        'uid': user.id,
        'nombre': (inspectorProfile?['full_name'] ?? user.email) as String?,
        'rango': (inspectorProfile?['national_id'] ?? '') as String?, // usa tu campo de rango si ya lo tienes
      };

      final visitaJson = {
        'subsanadas_obs_previas': _subsanadasPrevias!,
        'emergencias_ultimo_anio': _emergenciasUltAnio!,
      };

      // Pre-creamos la inspección con Hoja 1 y la pasamos al wizard (módulos)
      final payload = {
        'inspector_id': user.id,
        'radicado': _radicadoCtrl.text.trim(),
        'fecha_inspeccion': _fecha!.toIso8601String(),
        'nombre_comercial': _nombreComCtrl.text.trim(),
        'representante_legal': _repLegalCtrl.text.trim(),
        'direccion_rut': _dirRutCtrl.text.trim(),
        'celular_rut': _celularRutCtrl.text.trim(),
        'acompanante': _acompananteCtrl.text.trim(),
        'inspector': inspectorJson,
        'foto_fachada_url': _fotoFachadaUrl,
        'visita_anterior': visitaJson,
        'tipo_inspeccion': _tipoInspeccion,
        // placeholders; se llenarán en la evaluación
        'modules': [],
        'resultado': null,
      };

      final inserted = await supabase.from('inspections').insert(payload).select().single();
      final newId = inserted['id'] as String;

      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NewInspectionWizard(
          existing: Map<String, dynamic>.from(inserted),
          inspectionId: newId,
        ),
      ));
      if (!mounted) return;
      Navigator.of(context).pop(); // volver a listado tras terminar el wizard
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _fecha == null
        ? 'Selecciona fecha'
        : '${_fecha!.year}-${_fecha!.month.toString().padLeft(2, '0')}-${_fecha!.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Inspección — Hoja 1')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _radicadoCtrl,
              decoration: const InputDecoration(labelText: '# Radicado'),
              validator: _req,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Fecha: $dateText')),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) setState(() => _fecha = picked);
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text('Elegir'),
                ),
              ],
            ),
            const Divider(),
            TextFormField(
              controller: _nombreComCtrl,
              decoration: const InputDecoration(labelText: 'Nombre comercial'),
              validator: _req,
            ),
            TextFormField(
              controller: _repLegalCtrl,
              decoration: const InputDecoration(labelText: 'Representante legal'),
              validator: _req,
            ),
            TextFormField(
              controller: _dirRutCtrl,
              decoration: const InputDecoration(labelText: 'Dirección (RUT)'),
              validator: _req,
            ),
            TextFormField(
              controller: _celularRutCtrl,
              decoration: const InputDecoration(labelText: 'Celular (10 dígitos)'),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              validator: (v) {
                if (v == null || v.length != 10) return 'Debe tener 10 dígitos';
                return null;
              },
            ),
            TextFormField(
              controller: _acompananteCtrl,
              decoration: const InputDecoration(labelText: 'Acompañante'),
              validator: _req,
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
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Foto de fachada'),
              subtitle: _fotoFachadaUrl == null
                  ? const Text('Obligatoria')
                  : Image.network(_fotoFachadaUrl!, height: 140, fit: BoxFit.cover),
              trailing: OutlinedButton.icon(
                onPressed: _pickFachada,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Adjuntar'),
              ),
            ),
            const Divider(),
            const Text('Visita anterior', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<bool>(
              value: _subsanadasPrevias,
              items: const [
                DropdownMenuItem(value: true, child: Text('Sí, subsanadas')),
                DropdownMenuItem(value: false, child: Text('No subsanadas')),
              ],
              onChanged: (v) => setState(() => _subsanadasPrevias = v),
              decoration: const InputDecoration(labelText: '¿Se subsanaron observaciones previas?'),
            ),
            DropdownButtonFormField<bool>(
              value: _emergenciasUltAnio,
              items: const [
                DropdownMenuItem(value: true, child: Text('Sí, hubo emergencias')),
                DropdownMenuItem(value: false, child: Text('No hubo emergencias')),
              ],
              onChanged: (v) => setState(() => _emergenciasUltAnio = v),
              decoration: const InputDecoration(labelText: '¿Emergencias en el último año?'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _continuar,
              icon: const Icon(Icons.arrow_forward),
              label: Text(_saving ? 'Guardando...' : 'Continuar evaluación'),
            ),
          ],
        ),
      ),
    );
  }
}

