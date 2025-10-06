/// Tipo de respuesta
enum AnswerType { yn, abc }

/// Modelo de una pregunta
class ModuleQuestion {
  final String id;
  final String text;
  final AnswerType answerType;
  final int points;
  final Map<String, int>? scoreMap;

  const ModuleQuestion({
    required this.id,
    required this.text,
    required this.answerType,
    required this.points,
    this.scoreMap,
  });

  int get maxAchievablePoints {
    if (answerType == AnswerType.yn) {
      return points;
    }
    final map = scoreMap ?? const {'A': 10, 'B': 5, 'C': 0};
    var max = 0;
    for (final value in map.values) {
      if (value > max) max = value;
    }
    return max;
  }
}

/// Modelo de un módulo (grupo de preguntas)
class ModuleTemplate {
  final String title;
  final List<ModuleQuestion> items;
  const ModuleTemplate({required this.title, required this.items});
}

/// Set completo por tipo de inspección
class ModuleTemplateSet {
  final String code;
  final String name;
  final int passingScore;
  final int maxScore;
  final List<ModuleTemplate> modules;

  const ModuleTemplateSet({
    required this.code,
    required this.name,
    required this.passingScore,
    required this.maxScore,
    required this.modules,
  });
}

// =============================================================
// 🔥 PLANTILLAS ACTUALIZADAS (según las imágenes que enviaste)
// =============================================================

// Helper para crear plantilla con puntaje total y 70% mínimo
ModuleTemplateSet _makeTemplate({
  required String code,
  required String name,
  required List<ModuleTemplate> modules,
}) {
  final total = modules.fold<int>(
    0,
    (sum, m) =>
        sum + m.items.fold<int>(0, (s, q) => s + q.maxAchievablePoints),
  );
  final passing = (total * 0.7).round();
  return ModuleTemplateSet(
    code: code,
    name: name,
    modules: modules,
    passingScore: passing,
    maxScore: total,
  );
}

// =============================================================
// 🏪 COMERCIO PEQUEÑO
// =============================================================
final comercioPequenoTemplate = _makeTemplate(
  code: 'comercio_pequeno',
  name: 'Comercio pequeño',
  modules: [
    const ModuleTemplate(
      title: 'Evaluación general',
      items: [
        ModuleQuestion(
          id: 'extintores',
          text: '¿Cuenta con la cantidad adecuada de extintores?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'recarga',
          text: '¿Los extintores están recargados y con mantenimiento vigente?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'botiquin',
          text: '¿Cuenta con botiquín de primeros auxilios completo?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'senalizacion',
          text: '¿Tiene señalizaciones visibles y adecuadas?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'instalaciones',
          text: '¿Las instalaciones eléctricas están en buen estado?',
          answerType: AnswerType.yn,
          points: 10,
        ),
      ],
    ),
  ],
);

// =============================================================
// 🏢 COMERCIO GRANDE
// =============================================================
final comercioGrandeTemplate = _makeTemplate(
  code: 'comercio_grande',
  name: 'Comercio grande',
  modules: [
    const ModuleTemplate(
      title: 'Protección y seguridad general',
      items: [
        ModuleQuestion(
          id: 'salidas',
          text: '¿Las salidas de emergencia están señalizadas y libres?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'extintores',
          text: '¿Los extintores cumplen con las normas vigentes?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'plan_emergencia',
          text: '¿Cuenta con plan de emergencia y evacuación actualizado?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'botiquin',
          text: '¿Dispone de botiquín completo y accesible?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'senales',
          text: '¿Señales de seguridad correctamente instaladas?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'instalaciones',
          text: '¿Instalaciones eléctricas seguras?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'brigada',
          text: '¿Existe brigada de emergencia entrenada?',
          answerType: AnswerType.yn,
          points: 10,
        ),
      ],
    ),
  ],
);

// =============================================================
// ⛽ ESTACIÓN DE SERVICIO
// =============================================================
final estacionServicioTemplate = _makeTemplate(
  code: 'estacion_servicio',
  name: 'Estación de servicio',
  modules: [
    ModuleTemplate(
      title: 'Seguridad contra incendios',
      items: [
        ModuleQuestion(
          id: 'plan_emergencia',
          text: '¿Cuenta con plan de emergencia completo?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'tuberias',
          text: '¿Las tuberías se encuentran en buen estado sin fugas?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'tanques',
          text: '¿Los tanques de almacenamiento cumplen con medidas reglamentarias?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'canaletas',
          text: '¿Las canaletas antiderrames están limpias y funcionales?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'extintores',
          text: '¿Dispone de extintores adecuados y vigentes?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'botiquin',
          text: '¿Cuenta con botiquín completo?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'senalizacion',
          text: '¿Cuenta con señalización visible?',
          answerType: AnswerType.yn,
          points: 10,
        ),
      ],
    ),
  ],
);

// =============================================================
// 🏭 INDUSTRIA
// =============================================================
final industriaTemplate = _makeTemplate(
  code: 'industria',
  name: 'Industria',
  modules: [
    ModuleTemplate(
      title: 'Seguridad industrial y prevención',
      items: [
        ModuleQuestion(
          id: 'sistema_alarma',
          text: '¿Cuenta con sistema de alarma contra incendios funcional?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'hidrantes',
          text: '¿Tiene hidrantes operativos y accesibles?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'extintores',
          text: '¿Extintores suficientes y en buen estado?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'rutas_evacuacion',
          text: '¿Rutas de evacuación señalizadas y libres?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'equipos_proteccion',
          text: '¿El personal cuenta con equipos de protección personal?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'plan_emergencia',
          text: '¿Tiene plan de emergencia vigente y aprobado?',
          answerType: AnswerType.yn,
          points: 10,
        ),
        ModuleQuestion(
          id: 'capacitacion',
          text: '¿El personal ha recibido capacitación en manejo de emergencias?',
          answerType: AnswerType.yn,
          points: 10,
        ),
      ],
    ),
  ],
);

// =============================================================
// MAPEO GENERAL
// =============================================================
final Map<String, ModuleTemplateSet> _templatesMap = {
  'comercio_pequeno': comercioPequenoTemplate,
  'comercio_grande': comercioGrandeTemplate,
  'estacion_servicio': estacionServicioTemplate,
  'industria': industriaTemplate,
};

ModuleTemplateSet templatesByType(String type) {
  return _templatesMap[type] ?? comercioPequenoTemplate;
}

String normalizeTemplateCode(String? value) {
  final raw = (value ?? '').trim().toLowerCase();
  if (raw.isEmpty) return 'comercio_pequeno';
  final normalized = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  if (normalized.contains('grande')) return 'comercio_grande';
  if (normalized.contains('peque')) return 'comercio_pequeno';
  if (normalized.contains('estacion')) return 'estacion_servicio';
  if (normalized.contains('indus')) return 'industria';
  return 'comercio_pequeno';
}
