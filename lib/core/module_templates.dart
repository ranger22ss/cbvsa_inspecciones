import 'templates.dart';

class AnswerType {
  static const yn = 'yn';   // Sí / No / N/A -> suma puntos solo con "sí"
  static const abc = 'abc'; // A / B / C     -> usa scoreMap
}

class ModuleQuestion {
  final String id;
  final String text;
  final int points;
  final String answerType;
  final Map<String, int>? scoreMap;
  const ModuleQuestion({
    required this.id,
    required this.text,
    required this.points,
    required this.answerType,
    this.scoreMap,
  });
}

class ModuleDef {
  final String title;
  final List<ModuleQuestion> items;
  const ModuleDef({required this.title, required this.items});
}

class ModuleTemplateSet {
  final List<ModuleDef> modules;
  final int passingScore;
  const ModuleTemplateSet({required this.modules, required this.passingScore});
int get maxScore {
  int total = 0;
  for (final module in modules) {
    for (final q in module.items) {
      if (q.answerType == AnswerType.yn) {
        total += q.points;
      } else if (q.scoreMap != null) {
        // toma el valor más alto del mapa de puntajes (A/B/C)
        total += q.scoreMap!.values.reduce((a, b) => a > b ? a : b);
      }
    }
  }
  return total;
}
}

final comercioPequeno = ModuleTemplateSet(
  passingScore: 70,
  modules: [
    ModuleDef(
      title: 'Módulo No. 1. Sistemas eléctricos',
      items: [
        ModuleQuestion(
          id: 'elec_tablero',
          text: '¿Tablero con protecciones y señalización?',
          points: 10,
          answerType: AnswerType.yn,
        ),
        ModuleQuestion(
          id: 'elec_cableado',
          text: 'Estado del cableado (A excelente / B aceptable / C deficiente)',
          points: 10,
          answerType: AnswerType.abc,
          scoreMap: {'A': 10, 'B': 5, 'C': 0},
        ),
      ],
    ),
    ModuleDef(
      title: 'Módulo No. 2. Vías de evacuación',
      items: [
        ModuleQuestion(
          id: 'vias_salida',
          text: '¿Salida de emergencia libre y señalizada?',
          points: 20,
          answerType: AnswerType.yn,
        ),
        ModuleQuestion(
          id: 'rutas_senial',
          text: 'Señalización de rutas (A completa / B parcial / C inexistente)',
          points: 10,
          answerType: AnswerType.abc,
          scoreMap: {'A': 10, 'B': 5, 'C': 0},
        ),
      ],
    ),
  ],
);

final comercioGrande = ModuleTemplateSet(
  passingScore: 80,
  modules: [
    ModuleDef(
      title: 'Módulo No. 1. Protección activa',
      items: [
        ModuleQuestion(
          id: 'extintores',
          text: '¿Extintores suficientes, señalizados y con mantenimiento?',
          points: 15,
          answerType: AnswerType.yn,
        ),
        ModuleQuestion(
          id: 'alarmas',
          text: 'Sistema de alarma (A operativo / B intermitente / C inoperativo)',
          points: 15,
          answerType: AnswerType.abc,
          scoreMap: {'A': 15, 'B': 8, 'C': 0},
        ),
      ],
    ),
  ],
);

final estacionServicio = ModuleTemplateSet(
  passingScore: 85,
  modules: [
    ModuleDef(
      title: 'Módulo No. 1. Seguridad en despacho',
      items: [
        ModuleQuestion(
          id: 'antiderrames',
          text: '¿Kit antiderrames disponible y completo?',
          points: 20,
          answerType: AnswerType.yn,
        ),
      ],
    ),
  ],
);

final industria = ModuleTemplateSet(
  passingScore: 90,
  modules: [
    ModuleDef(
      title: 'Módulo No. 1. Maquinaria',
      items: [
        ModuleQuestion(
          id: 'guardas',
          text: '¿Guardas y paros de emergencia en máquinas?',
          points: 20,
          answerType: AnswerType.yn,
        ),
      ],
    ),
  ],
);

ModuleTemplateSet templatesByType(String? tipo) {
  final normalized = normalizeTemplateCode(tipo);
  switch (normalized) {
    case 'comercio_grande':
      return comercioGrande;
    case 'estacion_servicio':
      return estacionServicio;
    case 'industria':
      return industria;
    case 'comercio_pequeno':
    default:
      return comercioPequeno;
  }
}
