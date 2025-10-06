import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/module_templates.dart';
import '../../core/providers.dart';
import '../../core/storage.dart';

/// Wizard de tres pasos para crear o editar inspecciones.
///
/// Paso 1  -> Datos iniciales (Hoja 1)
/// Paso 2  -> Evaluación por módulos (Hoja 2)
/// Paso 3  -> Resumen y guardado (Hoja 3)
class NewInspectionWizard extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final String? inspectionId;

  const NewInspectionWizard({super.key, this.existing, this.inspectionId});

  @override
  ConsumerState<NewInspectionWizard> createState() => _NewInspectionWizardState();
}

class _NewInspectionWizardState extends ConsumerState<NewInspectionWizard> {
  final _stepOneKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // --- Campos Hoja 1 ---
  final _radicadoCtrl = TextEditingController();
  DateTime? _fechaInspeccion;
  final _nombreComCtrl = TextEditingController();
  final _representanteCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _acompananteCtrl = TextEditingController();

  bool? _subsanadasPrevias;
  bool? _emergenciasUltAnio;
  String _tipoInspeccion = 'comercio_pequeno';
  String? _fotoFachadaUrl;

  // --- Evaluación por módulos ---
  late ModuleTemplateSet _template;
  Map<String, String> _answers = <String, String>{};
  Map<String, List<Map<String, String>>> _photos =
      <String, List<Map<String, String>>>{};
  int _score = 0;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyExistingData(widget.existing);
    _applyTemplate(_tipoInspeccion);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _radicadoCtrl.dispose();
    _nombreComCtrl.dispose();
    _representanteCtrl.dispose();
    _direccionCtrl.dispose();
    _celularCtrl.dispose();
    _acompananteCtrl.dispose();
    super.dispose();
  }

  void _applyExistingData(Map<String, dynamic>? existing) {
    if (existing == null) return;
    _radicadoCtrl.text = (existing['radicado'] ?? '').toString();
    final fechaRaw = existing['fecha_inspeccion'];
    if (fechaRaw is String) {
      _fechaInspeccion = DateTime.tryParse(fechaRaw);
    } else if (fechaRaw is DateTime) {
      _fechaInspeccion = fechaRaw;
    }
    _nombreComCtrl.text = (existing['nombre_comercial'] ?? '').toString();
    _representanteCtrl.text = (existing['representante_legal'] ?? '').toString();
    _direccionCtrl.text = (existing['direccion_rut'] ?? '').toString();
    _celularCtrl.text = (existing['celular_rut'] ?? '').toString();
    _acompananteCtrl.text = (existing['acompanante'] ?? '').toString();

    final visita = existing['visita_anterior'];
    if (visita is Map) {
      final map = Map<String, dynamic>.from(visita);
      _subsanadasPrevias = map['subsanadas_obs_previas'] as bool?;
      _emergenciasUltAnio = map['emergencias_ultimo_anio'] as bool?;
    }

    final tipo = normalizeTemplateCode(existing['tipo_inspeccion'] as String?);
    if (tipo.isNotEmpty) {
      _tipoInspeccion = tipo;
    }

    _fotoFachadaUrl = existing['foto_fachada_url'] as String?;

    final modules = existing['modules'];
    if (modules is List) {
      final parsed = modules.cast<Map<String, dynamic>>();
      final tempAnswers = <String, String>{};
      final tempPhotos = <String, List<Map<String, String>>>{};
      for (var moduleIndex = 0; moduleIndex < parsed.length; moduleIndex++) {
        final module = parsed[moduleIndex];
        final items = module['items'];
        if (items is List) {
          for (final item in items) {
            if (item is! Map) continue;
            final map = Map<String, dynamic>.from(item);
            final questionId = (map['pregunta_id'] ?? map['id'] ?? '')
                .toString()
                .trim();
            if (questionId.isEmpty) continue;
            final key = '${moduleIndex}_$questionId';
            final respuesta = map['respuesta'];
            if (respuesta != null) {
              tempAnswers[key] = respuesta.toString();
            }
            final fotos = map['fotos'];
            if (fotos is List) {
              tempPhotos[key] = fotos
                  .whereType<Map>()
                  .map((f) => f.map((key, value) => MapEntry(
                        key.toString(),
                        value?.toString() ?? '',
                      )))
                  .toList();
            }
          }
        }
      }
      _answers = tempAnswers;
      _photos = tempPhotos;
    }

    final resultado = existing['resultado'];
    if (resultado is Map) {
      final map = Map<String, dynamic>.from(resultado);
      _score = (map['puntaje_total'] as num?)?.toInt() ?? 0;
    }
  }

  void _applyTemplate(String? rawTipo) {
    final normalized = normalizeTemplateCode(rawTipo);
    final template = templatesByType(normalized);
    final newAnswers = <String, String>{};
    final newPhotos = <String, List<Map<String, String>>>{};

    for (var moduleIndex = 0;
        moduleIndex < template.modules.length;
        moduleIndex++) {
      final module = template.modules[moduleIndex];
      for (final question in module.items) {
        final key = '${moduleIndex}_${question.id}';
        var existingAnswer = _answers[key];
        if (question.answerType == AnswerType.yn) {
          if (existingAnswer != 'yes' &&
              existingAnswer != 'no' &&
              existingAnswer != 'na') {
            existingAnswer = 'no';
          }
        } else {
          if (existingAnswer != 'A' &&
              existingAnswer != 'B' &&
              existingAnswer != 'C') {
            existingAnswer = 'C';
          }
        }
        newAnswers[key] = existingAnswer ??
            (question.answerType == AnswerType.yn ? 'no' : 'C');
        final existingPhotos = _photos[key];
        newPhotos[key] = existingPhotos != null
            ? List<Map<String, String>>.from(existingPhotos)
            : <Map<String, String>>[];
      }
    }

    setState(() {
      _tipoInspeccion = normalized;
      _template = template;
      _answers = newAnswers;
      _photos = newPhotos;
    });
    _recalculateScore();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInspeccion ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _fechaInspeccion = picked);
    }
  }

  Future<void> _pickFachada() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La carga de imágenes no está soportada en web.')),
      );
      return;
    }

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

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    await _uploadFachada(File(picked.path));
  }

  Future<void> _uploadFachada(File file) async {
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final storage = StorageService(supabase);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subiendo foto de fachada...')),
    );

    try {
      final url = await storage.uploadImage(
        file: file,
        userId: user.id,
        questionId: 'fachada',
      );
      if (!mounted) return;
      setState(() => _fotoFachadaUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de fachada subida ✔')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo fachada: $e')),
      );
    }
  }

  void _recalculateScore() {
    var total = 0;
    for (var moduleIndex = 0;
        moduleIndex < _template.modules.length;
        moduleIndex++) {
      final module = _template.modules[moduleIndex];
      for (final question in module.items) {
        final key = '${moduleIndex}_${question.id}';
        final answer = _answers[key];
        if (question.answerType == AnswerType.yn) {
          if (answer == 'yes') total += question.points;
        } else {
          final map = question.scoreMap ?? const {'A': 10, 'B': 5, 'C': 0};
          total += map[answer] ?? 0;
        }
      }
    }
    setState(() => _score = total);
  }

  Widget _buildAnswerField(ModuleQuestion question, String key) {
    if (question.answerType == AnswerType.yn) {
      return DropdownButtonFormField<String>(
        value: _answers[key],
        items: [
          const DropdownMenuItem(value: 'yes', child: Text('Sí / Cumple')),
          const DropdownMenuItem(value: 'no', child: Text('No cumple')),
          const DropdownMenuItem(value: 'na', child: Text('No aplica')),
        ],
        onChanged: (value) {
          setState(() => _answers[key] = value ?? 'no');
          _recalculateScore();
        },
        decoration: const InputDecoration(labelText: 'Resultado'),
      );
    }

    return DropdownButtonFormField<String>(
      value: _answers[key],
      items: [
        const DropdownMenuItem(value: 'A', child: Text('A')),
        const DropdownMenuItem(value: 'B', child: Text('B')),
        const DropdownMenuItem(value: 'C', child: Text('C')),
      ],
      onChanged: (value) {
        setState(() => _answers[key] = value ?? 'C');
        _recalculateScore();
      },
      decoration: const InputDecoration(labelText: 'Resultado (A/B/C)'),
    );
  }

  Future<void> _addPhoto(String key) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La captura de fotos no está soportada en web.')),
      );
      return;
    }
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

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

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final storage = StorageService(supabase);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subiendo evidencia...')),
    );

    try {
      final url = await storage.uploadImage(
        file: File(picked.path),
        userId: user.id,
        questionId: key.replaceAll('_', '/'),
      );
      final list = List<Map<String, String>>.from(_photos[key] ?? []);
      list.add({'url': url, 'observacion': ''});
      setState(() => _photos[key] = list);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida ✔')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir foto: $e')),
      );
    }
  }

  Widget _photosBlock(String key) {
    final list = _photos[key] ?? const <Map<String, String>>[];
    if (list.isEmpty) return const Text('Sin fotos adjuntas');

    return Column(
      children: List.generate(list.length, (index) {
        final entry = list[index];
        final url = entry['url'] ?? '';
        final obs = entry['observacion'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (url.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover),
                )
              else
                const Icon(Icons.photo, size: 48),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: obs,
                  onChanged: (value) => _photos[key]?[index]['observacion'] = value,
                  decoration: const InputDecoration(labelText: 'Observación'),
                  maxLines: 2,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar foto',
                onPressed: () {
                  setState(() {
                    final current = List<Map<String, String>>.from(_photos[key] ?? []);
                    current.removeAt(index);
                    _photos[key] = current;
                  });
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        );
      }),
    );
  }

  bool _validateStepOne() {
    if (!(_stepOneKey.currentState?.validate() ?? false)) {
      return false;
    }
    if (_fechaInspeccion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione la fecha de inspección')),
      );
      return false;
    }
    if (_subsanadasPrevias == null || _emergenciasUltAnio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete la información de la visita anterior')),
      );
      return false;
    }
    if (_fotoFachadaUrl == null || _fotoFachadaUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe adjuntar la foto de la fachada')),
      );
      return false;
    }
    return true;
  }

  Future<void> _goToStep(int step) async {
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Map<String, dynamic>> _buildModulesPayload() {
    final modulesJson = <Map<String, dynamic>>[];
    for (var moduleIndex = 0;
        moduleIndex < _template.modules.length;
        moduleIndex++) {
      final module = _template.modules[moduleIndex];
      final items = <Map<String, dynamic>>[];
      for (final question in module.items) {
        final key = '${moduleIndex}_${question.id}';
        final answer = _answers[key];
        int points = 0;
        if (question.answerType == AnswerType.yn) {
          if (answer == 'yes') points = question.points;
        } else {
          final map = question.scoreMap ?? const {'A': 10, 'B': 5, 'C': 0};
          points = map[answer] ?? 0;
        }
        final fotos = (_photos[key] ?? [])
            .where((entry) => (entry['url'] ?? '').isNotEmpty)
            .map((entry) => {
                  'url': entry['url'],
                  if ((entry['observacion'] ?? '').trim().isNotEmpty)
                    'observacion': entry['observacion']!.trim(),
                })
            .toList();
        items.add({
          'pregunta_id': question.id,
          'pregunta_texto': question.text,
          'respuesta': answer,
          'puntaje': points,
          'fotos': fotos,
        });
      }
      modulesJson.add({'titulo': module.title, 'items': items});
    }
    return modulesJson;
  }

  List<_ModuleSummary> _buildModuleSummaries() {
    final summaries = <_ModuleSummary>[];
    for (var moduleIndex = 0;
        moduleIndex < _template.modules.length;
        moduleIndex++) {
      final module = _template.modules[moduleIndex];
      final items = <_ModuleItemSummary>[];
      for (final question in module.items) {
        final key = '${moduleIndex}_${question.id}';
        final answer = _answers[key] ?? '';
        final points = question.answerType == AnswerType.yn
            ? (answer == 'yes' ? question.points : 0)
            : (question.scoreMap ?? const {'A': 10, 'B': 5, 'C': 0})[answer] ?? 0;
        items.add(_ModuleItemSummary(
          question: question.text,
          answer: answer,
          points: points,
        ));
      }
      summaries.add(_ModuleSummary(title: module.title, items: items));
    }
    return summaries;
  }

  Future<void> _saveInspection() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final inspectorProfile = await supabase
          .from('profiles')
          .select('full_name, national_id, rank')
          .eq('id', user.id)
          .maybeSingle();

      final inspectorJson = {
        'uid': user.id,
        'nombre': inspectorProfile?['full_name'] ?? user.email,
        'rango': inspectorProfile?['rank'] ?? '',
        'documento': inspectorProfile?['national_id'] ?? '',
      };

      final modulesJson = _buildModulesPayload();
      final aprobado = _score >= _template.passingScore;

      final payload = {
        'inspector_id': user.id,
        'radicado': _radicadoCtrl.text.trim(),
        'fecha_inspeccion': _fechaInspeccion!.toIso8601String(),
        'nombre_comercial': _nombreComCtrl.text.trim(),
        'representante_legal': _representanteCtrl.text.trim(),
        'direccion_rut': _direccionCtrl.text.trim(),
        'celular_rut': _celularCtrl.text.trim(),
        'acompanante': _acompananteCtrl.text.trim(),
        'foto_fachada_url': _fotoFachadaUrl,
        'visita_anterior': {
          'subsanadas_obs_previas': _subsanadasPrevias,
          'emergencias_ultimo_anio': _emergenciasUltAnio,
        },
        'tipo_inspeccion': _tipoInspeccion,
        'modules': modulesJson,
        'resultado': {
          'puntaje_total': _score,
          'aprobado': aprobado,
          'puntaje_minimo': _template.passingScore,
        },
        'inspector': inspectorJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (widget.inspectionId != null) {
        await supabase
            .from('inspections')
            .update(payload)
            .eq('id', widget.inspectionId as Object);
      } else {
        await supabase.from('inspections').insert(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspección guardada correctamente')), 
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildStepOne() {
  final dateText = _fechaInspeccion == null
      ? 'Selecciona fecha'
      : '${_fechaInspeccion!.year}-${_fechaInspeccion!.month.toString().padLeft(2, '0')}-${_fechaInspeccion!.day.toString().padLeft(2, '0')}';

  return Form(
    key: _stepOneKey,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextFormField(
          controller: _radicadoCtrl,
          decoration: const InputDecoration(labelText: '# Radicado'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 12),

        // Fecha
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha de inspección'),
          subtitle: Text(dateText),
          trailing: OutlinedButton.icon(
            onPressed: _pickFecha,
            icon: const Icon(Icons.date_range),
            label: const Text('Elegir'),
          ),
        ),
        const Divider(),

        TextFormField(
          controller: _nombreComCtrl,
          decoration: const InputDecoration(labelText: 'Nombre comercial'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _representanteCtrl,
          decoration: const InputDecoration(labelText: 'Representante legal'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _direccionCtrl,
          decoration: const InputDecoration(labelText: 'Dirección (RUT)'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _celularCtrl,
          decoration:
              const InputDecoration(labelText: 'Celular (10 dígitos)'),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Campo requerido';
            }
            if (value.trim().length != 10) {
              return 'Debe tener 10 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _acompananteCtrl,
          decoration: const InputDecoration(labelText: 'Acompañante'),
        ),
        const SizedBox(height: 12),

        // 🔹 Dropdown tipo inspección (CORREGIDO)
        DropdownButtonFormField<String>(
          value: _tipoInspeccion,
          items: [
            const DropdownMenuItem<String>(
                value: 'comercio_pequeno', child: Text('Comercio pequeño')),
            const DropdownMenuItem<String>(
                value: 'comercio_grande', child: Text('Comercio grande')),
            const DropdownMenuItem<String>(
                value: 'estacion_servicio', child: Text('Estación de servicio')),
            const DropdownMenuItem<String>(
                value: 'industria', child: Text('Industria')),
          ],
          onChanged: (String? value) {
            if (value == null) return;
            setState(() => _tipoInspeccion = value);
            _applyTemplate(value);
          },
          decoration: const InputDecoration(labelText: 'Tipo de inspección'),
        ),
        const SizedBox(height: 12),

        // Foto fachada
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Foto de fachada'),
          subtitle: _fotoFachadaUrl == null
              ? const Text('Obligatoria')
              : Image.network(
                  _fotoFachadaUrl!,
                  height: 140,
                  fit: BoxFit.cover,
                ),
          trailing: OutlinedButton.icon(
            onPressed: _pickFachada,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Adjuntar'),
          ),
        ),
        const Divider(),

        // 🔹 Dropdown subsanadas previas
        DropdownButtonFormField<bool>(
          value: _subsanadasPrevias,
          decoration: const InputDecoration(
              labelText: '¿Se subsanaron observaciones previas?'),
          items: const [
            DropdownMenuItem<bool>(
                value: true, child: Text('Sí, subsanadas')),
            DropdownMenuItem<bool>(
                value: false, child: Text('No se subsanaron')),
          ],
          onChanged: (bool? value) =>
              setState(() => _subsanadasPrevias = value),
        ),
        const SizedBox(height: 12),

        // 🔹 Dropdown emergencias último año
        DropdownButtonFormField<bool>(
          value: _emergenciasUltAnio,
          decoration: const InputDecoration(
              labelText: '¿Emergencias en el último año?'),
          items: [
            const DropdownMenuItem<bool>(
                value: true, child: Text('Sí hubo emergencias')),
            const DropdownMenuItem<bool>(
                value: false, child: Text('No hubo emergencias')),
          ],
          onChanged: (bool? value) =>
              setState(() => _emergenciasUltAnio = value),
        ),
        const SizedBox(height: 24),

        FilledButton.icon(
          onPressed: () {
            if (_validateStepOne()) {
              _goToStep(1);
            }
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continuar con Hoja 2'),
        ),
      ],
    ),
  );
}


  Widget _buildStepTwo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Puntaje actual: $_score / Mínimo ${_template.passingScore}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (var moduleIndex = 0;
            moduleIndex < _template.modules.length;
            moduleIndex++)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _template.modules[moduleIndex].title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final question in _template.modules[moduleIndex].items) ...[
                    Text(question.text,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _buildAnswerField(
                      question,
                      '${moduleIndex}_${question.id}',
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _addPhoto('${moduleIndex}_${question.id}'),
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Agregar foto'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          question.answerType == AnswerType.yn
                              ? '+${question.points} pts si cumple'
                              : 'Puntaje según A/B/C',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _photosBlock('${moduleIndex}_${question.id}'),
                    const Divider(),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _goToStep(0),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a Hoja 1'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  _recalculateScore();
                  _goToStep(2);
                },
                icon: const Icon(Icons.summarize),
                label: const Text('Ir a resumen'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    final aprobado = _score >= _template.passingScore;
    final moduleSummaries = _buildModuleSummaries();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Resumen final',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text('Radicado: ${_radicadoCtrl.text}'),
        Text('Fecha: ${_fechaInspeccion != null ? _fechaInspeccion!.toLocal().toString().split(' ').first : '—'}'),
        Text('Nombre comercial: ${_nombreComCtrl.text}'),
        Text('Representante: ${_representanteCtrl.text}'),
        Text('Dirección: ${_direccionCtrl.text}'),
        Text('Celular: ${_celularCtrl.text}'),
        Text('Acompañante: ${_acompananteCtrl.text}'),
        const Divider(),
        Text('Tipo de inspección: $_tipoInspeccion'),
        Text('Puntaje total: $_score / ${_template.passingScore}'),
        Chip(
          label: Text(aprobado ? 'APROBADO' : 'NO APROBADO'),
          backgroundColor: aprobado ? Colors.green[100] : Colors.red[100],
        ),
        const Divider(),
        Text('Módulos evaluados:',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final module in moduleSummaries) ...[
          Text(module.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          for (final item in module.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.question),
                  Text('Respuesta: ${item.answer}'),
                  Text('Puntaje: ${item.points}'),
                ],
              ),
            ),
          const Divider(),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _goToStep(1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a Hoja 2'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveInspection,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando...' : 'Guardar inspección'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.inspectionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar inspección' : 'Nueva inspección'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStepOne(),
          _buildStepTwo(),
          _buildStepThree(),
        ],
      ),
    );
  }
}

class _ModuleSummary {
  const _ModuleSummary({required this.title, required this.items});

  final String title;
  final List<_ModuleItemSummary> items;
}

class _ModuleItemSummary {
  const _ModuleItemSummary({required this.question, required this.answer, required this.points});

  final String question;
  final String answer;
  final int points;
}
