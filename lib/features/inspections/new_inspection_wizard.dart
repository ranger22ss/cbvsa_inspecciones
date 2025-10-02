import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../core/templates.dart';
import '../../core/storage.dart';

class NewInspectionWizard extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final String? inspectionId;

  const NewInspectionWizard({super.key, this.existing, this.inspectionId});

  @override
  ConsumerState<NewInspectionWizard> createState() => _NewInspectionWizardState();
}

class _NewInspectionWizardState extends ConsumerState<NewInspectionWizard> {
  final _formEstKey = GlobalKey<FormState>();

  // Paso A — Datos
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Paso B — Plantilla (NO nulo)
  String _templateCode = 'pequeno';

  // Paso C — Respuestas, notas y fotos
  // answer: 'yes' | 'no' | 'na'
  final Map<String, String> _answers = {};               // qId -> 'yes'/'no'/'na'
  final Map<String, String> _notes = {};                 // qId -> nota/sugerencia
  final Map<String, List<String>> _photos = {};          // qId -> [urls]

  final _picker = ImagePicker();
  bool _saving = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _nameCtrl.text = (ex['nombre_comercial'] ?? '') as String;
      _addrCtrl.text = (ex['direccion_rut'] ?? '') as String;
      _respCtrl.text = (ex['responsible'] ?? '') as String;
      _phoneCtrl.text = (ex['phone'] ?? '') as String;
      final t = (ex['tipo_inspeccion'] ?? 'pequeno') as String;
      if (t.isNotEmpty) _templateCode = t;

      final Map<String, dynamic>? ans =
          ex['answers'] == null ? null : Map<String, dynamic>.from(ex['answers'] as Map);
      if (ans != null) {
        ans.forEach((key, value) {
          final v = Map<String, dynamic>.from(value as Map);
          // Compatibilidad: si era bool, lo mapeamos
          final raw = v['answer'];
          if (raw is bool) {
            _answers[key] = raw ? 'yes' : 'no';
          } else if (raw is String) {
            _answers[key] = (raw == 'yes' || raw == 'no' || raw == 'na') ? raw : 'no';
          } else {
            _answers[key] = 'no';
          }
          _notes[key] = (v['note'] ?? '') as String;
          final pics = (v['photos'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _photos[key] = pics;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _respCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  int _calcScore(TemplateDef t) {
    int score = 0;
    for (final q in t.questions) {
      final a = _answers[q.id] ?? 'no';
      if (a == 'yes') score += q.points; // Solo “Cumple” suma
    }
    return score;
  }

  Future<void> _pickAndUpload(String questionId) async {
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

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser!;
    final storage = StorageService(supabase);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subiendo foto...')),
    );

    try {
      final url = await storage.uploadImage(
        file: File(picked.path),
        userId: user.id,
        questionId: questionId,
      );

      if (!mounted) return;
      setState(() {
        final list = _photos[questionId] ?? <String>[];
        list.add(url);
        _photos[questionId] = list;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto subida ✔')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo foto: $e')),
      );
    }
  }

  Future<void> _save() async {
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final t = templateByCode(_templateCode);
    final score = _calcScore(t);

    setState(() => _saving = true);
    try {
      final answersPayload = {
        for (final q in t.questions)
          q.id: {
            'text': q.text,
            'points': q.points,
            'answer': _answers[q.id] ?? 'no', // 'yes' | 'no' | 'na'
            'note': _notes[q.id] ?? '',
            'photos': _photos[q.id] ?? <String>[],
          }
      };

      final payload = {
        'inspector_id': user.id,
        'nombre_comercial': _nameCtrl.text.trim(),
        'direccion_rut': _addrCtrl.text.trim(),
        'responsible': _respCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'tipo_inspeccion': t.code,
        'answers': answersPayload,
        'score': score,
      };

      if (widget.inspectionId == null) {
        await supabase.from('inspections').insert(payload);
      } else {
        await supabase
            .from('inspections')
            .update(payload)
            .eq('id', widget.inspectionId!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.inspectionId == null ? 'Inspección guardada' : 'Inspección actualizada')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _photosGrid(String qId) {
    final urls = _photos[qId] ?? const <String>[];
    if (urls.isEmpty) return const Text('Sin fotos');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(urls[i], fit: BoxFit.cover),
      ),
    );
  }

  // Selector tri-estado para una pregunta
  Widget _answerSelector(String qId) {
    final val = _answers[qId] ?? 'no';
    return DropdownButtonFormField<String>(
      value: val,
      items: const [
        DropdownMenuItem(value: 'yes', child: Text('Cumple')),
        DropdownMenuItem(value: 'no', child: Text('No cumple')),
        DropdownMenuItem(value: 'na', child: Text('No aplica')),
      ],
      onChanged: (v) => setState(() => _answers[qId] = v ?? 'no'),
      decoration: const InputDecoration(labelText: 'Resultado'),
    );
  }

  List<Step> _buildSteps() {
    final t = templateByCode(_templateCode);

    return [
      Step(
        title: const Text('Establecimiento'),
        isActive: _step >= 0,
        state: _step > 0 ? StepState.complete : StepState.indexed,
        content: Form(
          key: _formEstKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _addrCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              TextFormField(
                controller: _respCtrl,
                decoration: const InputDecoration(labelText: 'Responsable'),
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
            ],
          ),
        ),
      ),
      Step(
        title: const Text('Plantilla'),
        isActive: _step >= 1,
        state: _step > 1 ? StepState.complete : StepState.indexed,
        content: DropdownButtonFormField<String>(
          value: _templateCode,
          items: templates
              .map<DropdownMenuItem<String>>(
                (tpl) => DropdownMenuItem<String>(
                  value: tpl.code,
                  child: Text(tpl.name),
                ),
              )
              .toList(),
          onChanged: (String? v) {
            if (v == null) return;
            setState(() => _templateCode = v);
          },
          decoration: const InputDecoration(labelText: 'Tipo de inspección'),
        ),
      ),
      Step(
        title: const Text('Evaluación'),
        isActive: _step >= 2,
        state: StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puntaje mínimo: ${t.passingScore}'),
            const SizedBox(height: 8),
            for (final q in t.questions) ...[
              Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _answerSelector(q.id),
              const SizedBox(height: 6),
              TextFormField(
                initialValue: _notes[q.id] ?? '',
                onChanged: (v) => _notes[q.id] = v,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Sugerencia del inspector',
                  hintText: 'Anota recomendación / acción correctiva',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUpload(q.id),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Agregar foto'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(_photos[q.id]?.length ?? 0)} foto(s)',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _photosGrid(q.id),
              const Divider(),
            ],
            const SizedBox(height: 8),
            Text('Puntaje actual: ${_calcScore(t)}'),
          ],
        ),
      ),
    ];
  }

  void _onStepContinue() {
    if (_step == 0 && _formEstKey.currentState?.validate() != true) return;
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _save();
    }
  }

  void _onStepCancel() {
    if (_step > 0) setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.inspectionId == null ? 'Nueva inspección' : 'Editar inspección';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _saving ? null : _onStepContinue,
        onStepCancel: _saving ? null : _onStepCancel,
        steps: _buildSteps(),
        controlsBuilder: (context, details) {
          return Row(
            children: [
              FilledButton(
                onPressed: details.onStepContinue,
                child: Text(_step < 2 ? 'Siguiente' : (_saving ? 'Guardando...' : 'Guardar')),
              ),
              const SizedBox(width: 12),
              if (_step > 0)
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Atrás'),
                ),
            ],
          );
        },
      ),
    );
  }
}
