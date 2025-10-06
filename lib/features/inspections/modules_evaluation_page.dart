import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/storage.dart';
import 'summary_conclusion_page.dart';
import '../../core/module_templates.dart';

class ModulesEvaluationPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> baseData;
  final String tipoInspeccion;
  const ModulesEvaluationPage({
    super.key,
    required this.baseData,
    required this.tipoInspeccion,
  });

  @override
  ConsumerState<ModulesEvaluationPage> createState() =>
      _ModulesEvaluationPageState();
}

class _ModulesEvaluationPageState extends ConsumerState<ModulesEvaluationPage> {
  late final String _tipoNormalizado;
  late final ModuleTemplateSet _tpl;
  final _picker = ImagePicker();
  final Map<String, String> _answers = {};
  final Map<String, String> _observations = {}; // 👈 Observaciones individuales
  final Map<String, List<Map<String, String>>> _photos = {};
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _tipoNormalizado = normalizeTemplateCode(widget.tipoInspeccion);
    _tpl = templatesByType(_tipoNormalizado);
    _recalc();
  }

  void _recalc() {
    int s = 0;
    for (int m = 0; m < _tpl.modules.length; m++) {
      final mod = _tpl.modules[m];
      for (final q in mod.items) {
        final key = '${m}_${q.id}';
        final a = _answers[key] ?? 'no';
        if (q.answerType == AnswerType.yn) {
          if (a == 'yes') s += q.points;
        }
      }
    }
    setState(() => _score = s);
  }

  Future<void> _addPhoto(String key) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
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
        ]),
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
        questionId: key.replaceAll('_', '/'),
      );
      final list = _photos[key] ?? <Map<String, String>>[];
      list.add({'url': url, 'observacion': ''});
      setState(() => _photos[key] = list);
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

  Widget _answerField(ModuleQuestion q, String key) {
    final val = _answers[key] ?? 'no';
    return DropdownButtonFormField<String>(
      value: val,
      items: const [
        DropdownMenuItem(value: 'yes', child: Text('Sí / Cumple')),
        DropdownMenuItem(value: 'no', child: Text('No cumple')),
        DropdownMenuItem(value: 'na', child: Text('No aplica')),
      ],
      onChanged: (v) {
        _answers[key] = v ?? 'no';
        _recalc();
      },
      decoration: const InputDecoration(labelText: 'Resultado'),
    );
  }

  Widget _photosBlock(String key) {
    final list = _photos[key] ?? const <Map<String, String>>[];
    if (list.isEmpty) return const Text('Sin fotos');
    return Column(
      children: List.generate(list.length, (i) {
        final url = list[i]['url']!;
        final obs = list[i]['observacion'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, height: 64, width: 64, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: obs,
                  onChanged: (v) => list[i]['observacion'] = v,
                  decoration: const InputDecoration(labelText: 'Observación de foto'),
                  maxLines: 2,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar foto',
                onPressed: () {
                  setState(() {
                    list.removeAt(i);
                    _photos[key] = List<Map<String, String>>.from(list);
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

  void _goSummary() {
    final modulesJson = <Map<String, dynamic>>[];
    for (int m = 0; m < _tpl.modules.length; m++) {
      final mod = _tpl.modules[m];
      final items = <Map<String, dynamic>>[];
      for (final q in mod.items) {
        final key = '${m}_${q.id}';
        final a = _answers[key] ?? 'no';
        final obs = _observations[key] ?? '';
        int pts = (a == 'yes') ? q.points : 0;

        final fotos = (_photos[key] ?? const <Map<String, String>>[])
            .map((e) => {
                  'url': e['url']!,
                  if ((e['observacion'] ?? '').isNotEmpty)
                    'observacion': e['observacion']
                })
            .toList();

        items.add({
          'pregunta_id': q.id,
          'pregunta_texto': q.text,
          'respuesta': a,
          'puntaje': pts,
          'observacion': obs,
          'fotos': fotos,
        });
      }
      modulesJson.add({'titulo': mod.title, 'items': items});
    }

    final aprobado = _score >= _tpl.passingScore;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SummaryConclusionPage(
        baseData: widget.baseData,
        tipoInspeccion: _tipoNormalizado,
        modules: modulesJson,
        passingScore: _tpl.passingScore,
        totalScore: _score,
        maxScore: _tpl.maxScore,
        aprobado: aprobado,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación por módulos (Hoja 2)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Puntaje mínimo: ${_tpl.passingScore} / Máximo: ${_tpl.maxScore} — Actual: $_score',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (int m = 0; m < _tpl.modules.length; m++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tpl.modules[m].title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final q in _tpl.modules[m].items) ...[
                      Text(q.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _answerField(q, '${m}_${q.id}'),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: _observations['${m}_${q.id}'] ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Observación general (opcional)',
                        ),
                        maxLines: 2,
                        onChanged: (v) => _observations['${m}_${q.id}'] = v,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _addPhoto('${m}_${q.id}'),
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Agregar foto'),
                          ),
                          const SizedBox(width: 8),
                          Text('+${q.points} pts si cumple'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _photosBlock('${m}_${q.id}'),
                      const Divider(),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _goSummary,
            icon: const Icon(Icons.summarize),
            label: const Text('Resumen y Conclusión →'),
          ),
        ],
      ),
    );
  }
}

