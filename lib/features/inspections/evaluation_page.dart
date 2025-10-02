import 'package:flutter/material.dart';

/// Dropdown a prueba de crashes:
class SafeDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final FormFieldValidator<T?>? validator;

  const SafeDropdownFormField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.decoration,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Dedup por value y mantener el primero
    final map = <T?, DropdownMenuItem<T>>{};
    for (final it in items) {
      map.putIfAbsent(it.value, () => it);
    }
    final unique = map.values.toList();

    // Si el value no está EXACTAMENTE 1 vez => null (evita assert)
    T? safe = value;
    if (safe != null) {
      final found = unique.where((e) => e.value == safe).length;
      if (found != 1) {
        // ignore: avoid_print
        print(
            'SafeDropdownFormField: value="$safe" not found exactly once (found=$found). Forcing null. Items=${unique.map((e)=>e.value).toList()}');
        safe = null;
      }
    }

    return DropdownButtonFormField<T>(
      value: safe,
      items: unique,
      onChanged: onChanged,
      decoration: decoration,
      validator: validator,
    );
  }
}

class EvaluationPage extends StatefulWidget {
  final Map<String, dynamic> initialData; // viene de Hoja 1
  const EvaluationPage({super.key, required this.initialData});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final Map<String, dynamic> _answers = {};

  // Claves válidas y sus labels (¡¡estas son las que valen como value!!)
  static const _tipos = <String>[
    'comercio_pequeno',
    'comercio_grande',
    'estacion_servicio',
    'industria',
  ];
  static String _labelTipo(String v) {
    switch (v) {
      case 'comercio_pequeno':  return 'Comercio pequeño';
      case 'comercio_grande':   return 'Comercio grande';
      case 'estacion_servicio': return 'Estación de servicio';
      case 'industria':         return 'Industria';
      default:                  return v;
    }
  }

  // El tipo viene de Hoja 1; si llega raro, lo saneamos a null.
  String? _tipo;

  @override
  void initState() {
    super.initState();
    final t = widget.initialData['tipo_inspeccion'] as String?;
    _tipo = _tipos.contains(t) ? t : null;
  }

  List<Map<String, dynamic>> _getQuestions(String tipo) {
    switch (tipo) {
      case 'comercio_pequeno':
        return [
          {'id': 'extintores',     'texto': '¿Cantidad de extintores adecuada?', 'opciones': ['Sí', 'No']},
          {'id': 'recarga',        'texto': '¿Extintores recargados?',           'opciones': ['Sí', 'No']},
          {'id': 'botiquin',       'texto': '¿Botiquín disponible?',             'opciones': ['Sí', 'No']},
          {'id': 'senalizacion',   'texto': '¿Señalizaciones correctas?',        'opciones': ['Sí', 'No']},
          {'id': 'instalaciones',  'texto': '¿Instalaciones en buen estado?',    'opciones': ['Sí', 'No']},
        ];
      case 'comercio_grande':
        return [
          {'id': 'todo', 'texto': 'Preguntas completas de comercio grande', 'opciones': ['Sí', 'No']},
        ];
      case 'estacion_servicio':
        return [
          {'id': 'plan_emergencia', 'texto': '¿Plan de emergencia?', 'opciones': ['Completo','Hecho pero vencido','Sin plan de emergencias']},
          {'id': 'tuberias',        'texto': '¿Tuberías en buen estado?', 'opciones': ['Todo correcto','Antiguas, revisar','Con fugas']},
        ];
      case 'industria':
        return [
          {'id': 'brigada',            'texto': '¿Cuenta con brigada contra incendios?', 'opciones': ['Sí', 'No']},
          {'id': 'sistemas_detectores','texto': '¿Sistemas de detección instalados?',   'opciones': ['Sí', 'No']},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Items del dropdown de tipo (CLAVES como value)
    final tipoItems = _tipos
        .map((v) => DropdownMenuItem<String>(value: v, child: Text(_labelTipo(v))))
        .toList();

    final preguntas = _tipo == null ? <Map<String, dynamic>>[] : _getQuestions(_tipo!);

    return Scaffold(
      appBar: AppBar(title: const Text('Hoja 2 - Evaluación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dropdown del tipo (aquí suele explotar si se mezcla clave/label; ahora no)
          SafeDropdownFormField<String>(
            value: _tipo,
            items: tipoItems,
            onChanged: (v) => setState(() => _tipo = v),
            decoration: const InputDecoration(
              labelText: 'Tipo de inspección',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null ? 'Seleccione un tipo' : null,
          ),
          const SizedBox(height: 12),

          if (_tipo == null)
            const Text('Seleccione el tipo para cargar las preguntas.'),
          if (_tipo != null)
            ...List.generate(preguntas.length, (index) {
              final p = preguntas[index];
              final id = p['id'] as String;
              final opciones = List<String>.from(p['opciones'] as List);

              final items = opciones
                  .map((op) => DropdownMenuItem<String>(value: op, child: Text(op)))
                  .toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['texto'], style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SafeDropdownFormField<String>(
                        value: _answers[id],
                        items: items,
                        onChanged: (val) => setState(() => _answers[id] = val),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Seleccione una respuesta',
                        ),
                        validator: (v) => v == null ? 'Seleccione una respuesta' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Observación del inspector',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _answers['${id}_obs'] = val,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tipo == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seleccione un tipo de inspección')),
            );
            return;
          }
          debugPrint('Tipo: $_tipo');
          debugPrint('Respuestas: $_answers');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evaluación (temporal) OK')),
          );
        },
        label: const Text('Continuar'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
