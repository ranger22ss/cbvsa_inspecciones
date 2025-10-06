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

  int get maxScore => modules.fold(
        0,
        (total, module) => total +
            module.items.fold(0, (subtotal, item) => subtotal + item.points),
      );
}

String _moduleTitle(String code) {
  switch (code) {
    case 'comercio_pequeno':
      return 'Checklist comercio pequeño';
    case 'comercio_mediano':
      return 'Checklist comercio mediano';
    case 'comercio_grande':
      return 'Checklist comercio grande';
    case 'estacion_servicio':
      return 'Checklist estación de servicio';
    case 'industria':
      return 'Checklist industria';
    default:
      return 'Checklist de verificación';
  }
}

ModuleTemplateSet templatesByType(String tipo) {
  final template = templateByCode(tipo);
  return ModuleTemplateSet(
    passingScore: template.passingScore,
    modules: [
      ModuleDef(
        title: _moduleTitle(template.code),
        items: template.questions
            .map(
              (q) => ModuleQuestion(
                id: q.id,
                text: q.text,
                points: q.points,
                answerType: AnswerType.yn,
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}
