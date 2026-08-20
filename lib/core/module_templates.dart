/// Tipo de respuesta de cada ítem.
enum AnswerType { yn, abc }

class ModuleQuestion {
  final String id;
  final String text;
  final AnswerType answerType;
  final int points;
  final Map<String, int>? scoreMap;
  final String? yesLabel;
  final String? noLabel;
  final String? naLabel;
  const ModuleQuestion({required this.id, required this.text, required this.answerType, required this.points, this.scoreMap, this.yesLabel, this.noLabel, this.naLabel});
  int get maxAchievablePoints {
    if (answerType == AnswerType.yn) return points;
    final map = scoreMap ?? const {'A': 10, 'B': 5, 'C': 0};
    return map.values.fold<int>(0, (max, value) => value > max ? value : max);
  }
}

class ModuleTemplate {
  final String title;
  final List<ModuleQuestion> items;
  const ModuleTemplate({required this.title, required this.items});
}

class ModuleTemplateSet {
  final String code;
  final String name;
  final int passingScore;
  final int maxScore;
  final List<ModuleTemplate> modules;
  const ModuleTemplateSet({required this.code, required this.name, required this.passingScore, required this.maxScore, required this.modules});
}

ModuleTemplateSet _makeTemplate({required String code, required String name, required int passingScore, required List<ModuleTemplate> modules}) {
  final total = modules.fold<int>(0, (sum, module) => sum + module.items.fold<int>(0, (subtotal, question) => subtotal + question.maxAchievablePoints));
  assert(total == 100, 'Cada cuestionario debe sumar exactamente 100 puntos.');
  return ModuleTemplateSet(code: code, name: name, passingScore: passingScore, maxScore: total, modules: modules);
}

final comercioPequenoTemplate = _makeTemplate(
  code: "comercio_pequeno",
  name: "Comercio pequeño",
  passingScore: 70,
  modules: [
    ModuleTemplate(
      title: "Cuestionario: Comercio pequeño",
      items: [
        ModuleQuestion(id: "extintor_riesgo", text: "¿Cuenta con extintor adecuado al riesgo existente?", answerType: AnswerType.yn, points: 12),
        ModuleQuestion(id: "extintor_estado", text: "¿El extintor se encuentra vigente, cargado, señalizado, visible y de fácil acceso?", answerType: AnswerType.yn, points: 10),
        ModuleQuestion(id: "instalaciones_electricas", text: "¿Las instalaciones eléctricas visibles se encuentran en condiciones seguras, sin empalmes improvisados, conductores expuestos o sobrecargas evidentes?", answerType: AnswerType.yn, points: 12),
        ModuleQuestion(id: "tableros_electricos", text: "¿Los tableros eléctricos se encuentran identificados, protegidos y libres de obstáculos?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "ruta_salida", text: "¿La ruta hacia la salida permanece despejada y permite una evacuación segura?", answerType: AnswerType.yn, points: 12),
        ModuleQuestion(id: "puerta_evacuacion", text: "¿La puerta o salida utilizada para evacuación puede abrirse fácilmente y sin obstáculos?", answerType: AnswerType.yn, points: 10),
        ModuleQuestion(id: "senalizacion_basica", text: "¿Existe señalización básica de salida y ubicación del extintor?", answerType: AnswerType.yn, points: 8),
        ModuleQuestion(id: "materiales_combustibles", text: "¿Los materiales combustibles se almacenan de manera segura y alejados de fuentes de ignición?", answerType: AnswerType.yn, points: 8),
        ModuleQuestion(id: "botiquin", text: "¿Botiquín completo e instalado de manera correcta?", answerType: AnswerType.yn, points: 8),
        ModuleQuestion(id: "personal_emergencia", text: "¿El personal conoce cómo comunicar una emergencia y utilizar inicialmente un extintor?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "orden_aseo", text: "¿Existe orden y aseo suficiente para evitar acumulación peligrosa de material combustible?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "accesos_emergencia", text: "¿Se encuentran libres de obstáculos los accesos para atención de una emergencia?", answerType: AnswerType.yn, points: 4),
      ],
    ),
  ],
);

final comercioGrandeTemplate = _makeTemplate(
  code: "comercio_grande",
  name: "Comercio grande",
  passingScore: 80,
  modules: [
    ModuleTemplate(
      title: "Cuestionario: Comercio grande",
      items: [
        ModuleQuestion(id: "extintores_riesgo", text: "¿Los extintores corresponden a los riesgos existentes y están distribuidos adecuadamente?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "extintores_estado", text: "¿Los extintores están vigentes, señalizados, visibles y accesibles?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "rutas_evacuacion", text: "¿Las rutas de evacuación se encuentran completamente despejadas?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "salidas_evacuacion", text: "¿Las salidas son suficientes y permiten una evacuación segura según las características del establecimiento?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "puertas_evacuacion", text: "¿Las puertas destinadas a evacuación funcionan correctamente y permanecen disponibles?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "senalizacion_emergencia", text: "¿Existe señalización visible de rutas, salidas y equipos de emergencia?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "iluminacion_emergencia", text: "¿Cuenta con iluminación de emergencia donde corresponda?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "instalaciones_electricas", text: "¿Las instalaciones eléctricas visibles presentan condiciones seguras?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "tableros_electricos", text: "¿Los tableros eléctricos están identificados, protegidos y despejados?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "deteccion_alarma", text: "¿Los sistemas de detección o alarma instalados funcionan correctamente, cuando sean requeridos?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "sistemas_contra_incendio", text: "¿Los gabinetes, redes o sistemas contra incendio existentes están accesibles y operativos?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "almacenamiento_mercancias", text: "¿El almacenamiento de mercancías mantiene condiciones seguras frente al riesgo de incendio?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "botiquin", text: "¿Botiquín completo, adecuado y bien ubicado?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "procedimientos_evacuacion", text: "¿Existen procedimientos básicos para evacuación y atención de emergencias?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "actuacion_incendio", text: "¿El personal conoce los procedimientos de actuación en caso de incendio?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "aforo_ocupacion", text: "¿Se encuentra controlado el aforo y la ocupación de los espacios?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "areas_especiales", text: "¿Las áreas técnicas, cocinas o zonas especiales cuentan con medidas de protección acordes al riesgo?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "orden_aseo_accesibilidad", text: "¿El establecimiento mantiene condiciones adecuadas de orden, aseo y accesibilidad para emergencias?", answerType: AnswerType.yn, points: 6),
      ],
    ),
  ],
);

final estacionServicioTemplate = _makeTemplate(
  code: "estacion_servicio",
  name: "Estación de servicio",
  passingScore: 85,
  modules: [
    ModuleTemplate(
      title: "Cuestionario: Estación de servicio",
      items: [
        ModuleQuestion(id: "extintores_combustibles", text: "¿Los extintores corresponden al riesgo de combustibles líquidos existente?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "botiquin", text: "¿Botiquín adecuado, completo y bien ubicado?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "distribucion_extintores", text: "¿La cantidad y distribución de extintores cubre las diferentes áreas de riesgo?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "islas_abastecimiento", text: "¿Las islas de abastecimiento permanecen libres de acumulación de materiales combustibles?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "corte_emergencia", text: "¿Existen dispositivos claramente identificados para suspensión o corte de emergencia del suministro?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "parada_emergencia", text: "¿Los dispositivos de parada de emergencia se encuentran accesibles y operativos?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "fuentes_ignicion", text: "¿Las tablas de aforo se encuentran en completo orden según la normativa y anexadas al plan de contingencia de la E.D.S.?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "senalizacion_prohibiciones", text: "¿Existe señalización de prohibición de fumar, apagar motor y otras advertencias necesarias?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "instalaciones_electricas", text: "¿Las instalaciones eléctricas de las zonas de riesgo presentan condiciones seguras?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "tableros_electricos", text: "¿Los tableros eléctricos están protegidos, identificados y accesibles?", answerType: AnswerType.yn, points: 3),
        ModuleQuestion(id: "almacenamiento_descarga", text: "¿Las zonas de almacenamiento y descarga de combustible se encuentran protegidas y controladas?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "procedimientos_descargue", text: "¿Existen procedimientos seguros para descargue de combustible?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "control_derrames", text: "¿La estación dispone de elementos para control inicial de derrames?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "drenajes", text: "¿Los sistemas de drenaje evitan condiciones peligrosas por acumulación o propagación de combustible?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "rutas_salidas", text: "¿Las rutas y salidas de evacuación se mantienen libres?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "punto_encuentro", text: "¿Existe señalización y punto de encuentro para evacuación?", answerType: AnswerType.yn, points: 3),
        ModuleQuestion(id: "procedimiento_emergencia", text: "¿El personal conoce el procedimiento ante incendio, derrame o fuga?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "medios_control", text: "¿El personal conoce y puede operar los medios iniciales de control disponibles?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "plan_emergencias", text: "¿Existe un plan para atención de emergencias?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "condiciones_generales", text: "¿Las condiciones generales de almacenamiento, orden y separación de sustancias son seguras?", answerType: AnswerType.yn, points: 7),
      ],
    ),
  ],
);

final industriaTemplate = _makeTemplate(
  code: "industria",
  name: "Industria",
  passingScore: 90,
  modules: [
    ModuleTemplate(
      title: "Cuestionario: Industria",
      items: [
        ModuleQuestion(id: "riesgos_proceso", text: "¿Se encuentran identificados los riesgos de incendio propios del proceso industrial?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "botiquin", text: "¿Botiquín adecuado, completo y bien ubicado?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "extintores_estado", text: "¿Los extintores se encuentran vigentes, señalizados y accesibles?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "distribucion_equipos", text: "¿La distribución de equipos contra incendio cubre adecuadamente las áreas de riesgo?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "sistemas_fijos", text: "¿Los sistemas fijos de protección contra incendio requeridos se encuentran operativos?", answerType: AnswerType.yn, points: 7),
        ModuleQuestion(id: "deteccion_alarma", text: "¿Los sistemas de detección y alarma instalados funcionan correctamente?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "rutas_evacuacion", text: "¿Las rutas de evacuación están libres y claramente identificadas?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "salidas_emergencia", text: "¿Las salidas de emergencia funcionan correctamente?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "iluminacion_senalizacion", text: "¿Cuenta con iluminación y señalización de emergencia donde corresponda?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "instalaciones_electricas", text: "¿Las instalaciones eléctricas presentan condiciones seguras para el proceso desarrollado?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "tableros_equipos", text: "¿Los tableros y equipos eléctricos están protegidos e identificados?", answerType: AnswerType.yn, points: 3),
        ModuleQuestion(id: "materiales_combustibles", text: "¿Los materiales combustibles están almacenados de acuerdo con sus características y riesgos?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "sustancias_peligrosas", text: "¿Las sustancias inflamables o peligrosas, cuando existen, se encuentran debidamente segregadas e identificadas?", answerType: AnswerType.yn, points: 6),
        ModuleQuestion(id: "fuentes_ignicion", text: "¿Existe control de fuentes de ignición y trabajos en caliente?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "maquinaria_procesos", text: "¿La maquinaria y los procesos con generación de calor cuentan con medidas de seguridad contra incendio?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "plan_emergencias", text: "¿Existe un plan de emergencias acorde con los riesgos de la empresa?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "personal_preparado", text: "¿Existe organización o personal preparado para responder inicialmente ante emergencias?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "mantenimiento_sistemas", text: "¿Se realizan inspecciones, mantenimiento o pruebas de los sistemas de protección contra incendio?", answerType: AnswerType.yn, points: 5),
        ModuleQuestion(id: "acceso_organismos", text: "¿Se mantienen accesibles las áreas para intervención de organismos de emergencia?", answerType: AnswerType.yn, points: 4),
        ModuleQuestion(id: "condiciones_generales", text: "¿La industria mantiene condiciones generales adecuadas de almacenamiento, orden y control de combustibles?", answerType: AnswerType.yn, points: 6),
      ],
    ),
  ],
);

final Map<String, ModuleTemplateSet> _templatesMap = {
  'comercio_pequeno': comercioPequenoTemplate,
  'comercio_grande': comercioGrandeTemplate,
  'estacion_servicio': estacionServicioTemplate,
  'industria': industriaTemplate,
};

ModuleTemplateSet templatesByType(String type) => _templatesMap[type] ?? comercioPequenoTemplate;

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
