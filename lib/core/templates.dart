class Question {
  final String id;
  final String text;
  final int points; // puntos si cumple
  const Question({required this.id, required this.text, required this.points});
}

class TemplateDef {
  final String code; // 'comercio_pequeno', 'comercio_grande', ...
  final String name;
  final int passingScore; // puntaje mínimo para “aprobado”
  final List<Question> questions;

  const TemplateDef({
    required this.code,
    required this.name,
    required this.passingScore,
    required this.questions,
  });

  int get maxScore =>
      questions.fold(0, (total, question) => total + question.points);
}

const templates = <TemplateDef>[
  TemplateDef(
    code: 'comercio_pequeno',
    name: 'Comercio pequeño',
    passingScore: 16,
    questions: [
      Question(
        id: 'extintor_tipo',
        text: 'Extintor adecuado al tipo de riesgo (mínimo tipo ABC)',
        points: 2,
      ),
      Question(
        id: 'extintor_vigente',
        text: 'Extintor vigente, señalado y visible',
        points: 2,
      ),
      Question(
        id: 'senial_rutas',
        text: 'Señalización de rutas de salida visible',
        points: 2,
      ),
      Question(
        id: 'salida_libre',
        text: 'Salida de emergencia libre de obstáculos',
        points: 2,
      ),
      Question(
        id: 'senial_emergencia',
        text: 'Señalización de emergencia visible y sin obstrucciones',
        points: 2,
      ),
      Question(
        id: 'botiquin',
        text: 'Botiquín visible y completo',
        points: 2,
      ),
      Question(
        id: 'iluminacion',
        text: 'Iluminación de emergencia lista en puntos estratégicos',
        points: 2,
      ),
      Question(
        id: 'instalaciones_limpias',
        text: 'Instalaciones limpias sin material inflamable',
        points: 2,
      ),
      Question(
        id: 'personal_capacitado',
        text: 'Personal capacitado en emergencias',
        points: 2,
      ),
      Question(
        id: 'senial_no_fumar',
        text: 'Señalización de “No fumar” en zonas de riesgo',
        points: 2,
      ),
      Question(
        id: 'mantenimiento_electrico',
        text: 'Mantenimiento básico anual en instalaciones eléctricas',
        points: 2,
      ),
      Question(
        id: 'uso_extintor',
        text: 'Personal conoce el uso del extintor',
        points: 2,
      ),
    ],
  ),
  TemplateDef(
    code: 'comercio_mediano',
    name: 'Comercio mediano',
    passingScore: 23,
    questions: [
      Question(
        id: 'plan_emergencia',
        text: 'Plan de emergencia visible y firmado',
        points: 3,
      ),
      Question(
        id: 'senial_rutas',
        text: 'Señalización de rutas de evacuación',
        points: 3,
      ),
      Question(
        id: 'extintores_suficientes',
        text: 'Extintores suficientes según el área y riesgo',
        points: 3,
      ),
      Question(
        id: 'recarga_extintores',
        text: 'Fecha de recarga vigente y accesible',
        points: 3,
      ),
      Question(
        id: 'salida_libre',
        text: 'Salida de emergencia libre y sin sobrecarga',
        points: 3,
      ),
      Question(
        id: 'brigada_operativa',
        text: 'Brigada de emergencia operativa',
        points: 3,
      ),
      Question(
        id: 'botiquin_completo',
        text: 'Botiquín y kit de primeros auxilios completo',
        points: 3,
      ),
      Question(
        id: 'capacitaciones',
        text: 'Personal capacitado en evacuaciones y uso de extintores',
        points: 3,
      ),
      Question(
        id: 'materiales_combustibles',
        text: 'No existen materiales combustibles junto a fuentes de calor',
        points: 3,
      ),
      Question(
        id: 'senales_fotoluminiscentes',
        text: 'Señales fotoluminiscentes visibles',
        points: 3,
      ),
      Question(
        id: 'orden_limpieza',
        text: 'Se conserva orden y limpieza general',
        points: 2,
      ),
    ],
  ),
  TemplateDef(
    code: 'comercio_grande',
    name: 'Comercio grande',
    passingScore: 40,
    questions: [
      Question(
        id: 'alarma_automatica',
        text: 'Sistema de detección y alarma automática funcionando',
        points: 4,
      ),
      Question(
        id: 'rociadores',
        text: 'Sistema de rociadores automáticos (si aplica) en funcionamiento',
        points: 4,
      ),
      Question(
        id: 'senializacion_completa',
        text: 'Señalización completa de evacuación y salidas',
        points: 4,
      ),
      Question(
        id: 'extintores_visibles',
        text: 'Extintores suficientes y visibles por área',
        points: 4,
      ),
      Question(
        id: 'brigadas',
        text: 'Personal entrenado en emergencias y brigadas internas',
        points: 4,
      ),
      Question(
        id: 'luces_emergencia',
        text: 'Luces de emergencia en pasillos y zonas críticas',
        points: 3,
      ),
      Question(
        id: 'hidrantes',
        text: 'Hidrantes internos y externos operativos',
        points: 3,
      ),
      Question(
        id: 'rutas_actualizadas',
        text: 'Señalización de rutas de evacuación actualizada',
        points: 3,
      ),
      Question(
        id: 'cableado_certificado',
        text: 'Cableado certificado y sin sobrecarga',
        points: 3,
      ),
      Question(
        id: 'equipos_mantenimiento',
        text: 'Equipos eléctricos con mantenimiento al día',
        points: 3,
      ),
      Question(
        id: 'almacenamiento_escaleras',
        text: 'No hay almacenamiento en escaleras o pasillos',
        points: 3,
      ),
      Question(
        id: 'senales_no_fumar',
        text: 'Señales de “No fumar / Material inflamable” visibles',
        points: 3,
      ),
      Question(
        id: 'rutas_libres',
        text: 'Rutas libres y señalizadas en todas las áreas',
        points: 3,
      ),
      Question(
        id: 'plan_por_zonas',
        text: 'Plan de emergencias general por zonas',
        points: 3,
      ),
      Question(
        id: 'registros_inspeccion',
        text: 'Registros de inspecciones vigentes y firmados',
        points: 3,
      ),
      Question(
        id: 'area_reunion',
        text: 'Área de reunión externa señalizada',
        points: 3,
      ),
    ],
  ),
  TemplateDef(
    code: 'estacion_servicio',
    name: 'Estación de servicio',
    passingScore: 60,
    questions: [
      Question(
        id: 'plan_emergencia',
        text: 'Plan de emergencia y contingencia vigente',
        points: 5,
      ),
      Question(
        id: 'personal_capacitado',
        text: 'Personal capacitado en manejo de incidentes y derrames',
        points: 5,
      ),
      Question(
        id: 'extintores_operativos',
        text: 'Extintores tipo PQS y CO₂ operativos y visibles',
        points: 5,
      ),
      Question(
        id: 'sistema_corte',
        text: 'Sistema de corte de energía y emergencias funcionando',
        points: 5,
      ),
      Question(
        id: 'area_sin_ignicion',
        text: 'Área libre de fuentes de ignición',
        points: 5,
      ),
      Question(
        id: 'senales_prohibido_fumar',
        text: 'Señalización de “Prohibido fumar” visible y suficiente',
        points: 5,
      ),
      Question(
        id: 'canaletas_limpias',
        text: 'Canaletas de almacenamiento limpias y funcionales (sin fugas)',
        points: 5,
      ),
      Question(
        id: 'tanques_limpios',
        text: 'Tanques de almacenamiento limpios y funcionales (sin fugas)',
        points: 5,
      ),
      Question(
        id: 'kit_antiderrames',
        text: 'Kit antiderrames y materiales absorbentes disponible',
        points: 5,
      ),
      Question(
        id: 'supervision_mangueras',
        text: 'Supervisión diaria de mangueras y válvulas',
        points: 5,
      ),
      Question(
        id: 'distancias_reglamentarias',
        text: 'Distancias reglamentarias entre surtidores y zonas de servicio',
        points: 5,
      ),
      Question(
        id: 'senalizacion_horizontal',
        text: 'Señalización horizontal y vertical reglamentaria',
        points: 5,
      ),
      Question(
        id: 'areas_tanques_limpias',
        text: 'Áreas de tanques y zonas críticas limpias y libres de residuos',
        points: 5,
      ),
      Question(
        id: 'drenajes',
        text: 'Drenajes y sistemas de contención limpios y funcionales',
        points: 5,
      ),
      Question(
        id: 'mantenimiento_surtidores',
        text: 'Surtidores con mantenimiento y registros al día',
        points: 5,
      ),
      Question(
        id: 'revision_diaria',
        text: 'Revisión diaria de áreas y accesorios disponibles',
        points: 5,
      ),
      Question(
        id: 'limpieza_general',
        text: 'Instalaciones limpias y libres de derrames',
        points: 5,
      ),
    ],
  ),
  TemplateDef(
    code: 'industria',
    name: 'Industria',
    passingScore: 80,
    questions: [
      Question(
        id: 'evaluacion_riesgo',
        text: 'Evaluación de riesgo de incendio documentada',
        points: 5,
      ),
      Question(
        id: 'brigada_interna',
        text: 'Brigada interna activa y capacitada',
        points: 5,
      ),
      Question(
        id: 'sistemas_deteccion',
        text: 'Sistemas automáticos (espuma, CO₂ o rociadores) funcionando',
        points: 5,
      ),
      Question(
        id: 'extintores_funcionales',
        text: 'Extintores suficientes y con mantenimiento vigente',
        points: 5,
      ),
      Question(
        id: 'deteccion_gases',
        text: 'Detectores de gases o vapores inflamables operativos',
        points: 5,
      ),
      Question(
        id: 'permiso_trabajo',
        text: 'Permiso de trabajo en caliente implementado',
        points: 5,
      ),
      Question(
        id: 'senalizacion_maquinaria',
        text: 'Señalización completa y visible en todas las áreas',
        points: 5,
      ),
      Question(
        id: 'capacitacion_personal',
        text: 'Personal capacitado en manejo de emergencias',
        points: 5,
      ),
      Question(
        id: 'sistemas_ventilacion',
        text: 'Sistemas de ventilación y extracción funcionando',
        points: 5,
      ),
      Question(
        id: 'almacenamiento_quimicos',
        text: 'Almacenamiento seguro de químicos y combustibles',
        points: 5,
      ),
      Question(
        id: 'mantenimiento_maquinaria',
        text: 'Mantenimiento preventivo de maquinaria documentado',
        points: 5,
      ),
      Question(
        id: 'rutas_evacuacion',
        text: 'Rutas de evacuación señalizadas y libres de obstáculos',
        points: 5,
      ),
      Question(
        id: 'sistema_iluminacion',
        text: 'Sistema de iluminación de emergencia operativo',
        points: 5,
      ),
      Question(
        id: 'politica_no_fumar',
        text: 'Política de “No fumar / Material inflamable” visible',
        points: 5,
      ),
      Question(
        id: 'control_polvoy_particulas',
        text: 'Control de polvo o partículas combustibles',
        points: 5,
      ),
      Question(
        id: 'gestion_residuos',
        text: 'Gestión adecuada de residuos peligrosos',
        points: 5,
      ),
      Question(
        id: 'proteccion_personal',
        text: 'Elementos de protección personal disponibles y en uso',
        points: 5,
      ),
      Question(
        id: 'control_transporte',
        text: 'Plan de acceso y transporte de materiales peligrosos',
        points: 5,
      ),
      Question(
        id: 'senalizacion_areas_carga',
        text: 'Señalización en áreas de carga y descarga',
        points: 5,
      ),
      Question(
        id: 'plan_emergencia_industrial',
        text: 'Plan de emergencias por vehículos de carga y visitantes',
        points: 5,
      ),
    ],
  ),
];

String _stripDiacritics(String value) {
  const Map<String, String> replacements = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

String _normalizeKey(String? raw) {
  if (raw == null) return '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final withoutDiacritics = _stripDiacritics(trimmed).toLowerCase();
  final collapsed = withoutDiacritics
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return collapsed.replaceAll(RegExp(r'^_|_$'), '');
}

String normalizeTemplateCode(String? code) {
  final key = _normalizeKey(code);
  switch (key) {
    case 'comercio_pequeno':
    case 'comerciopequeno':
    case 'comercio_pequena':
    case 'comerciominorista':
    case 'pequeno':
    case 'pequena':
    case 'pequenia':
      return 'comercio_pequeno';
    case 'comercio_grande':
    case 'comerciogrande':
    case 'grande':
    case 'gran_comercio':
      return 'comercio_grande';
    case 'comercio_mediano':
    case 'comerciomediano':
    case 'mediano':
      return 'comercio_mediano';
    case 'estacion_servicio':
    case 'estacionservicio':
    case 'estacion_de_servicio':
    case 'estacion':
    case 'gasolinera':
    case 'eds':
      return 'estacion_servicio';
    case 'industria':
    case 'industrial':
      return 'industria';
    default:
      return templates.first.code;
  }
}

TemplateDef templateByCode(String code) {
  final normalized = normalizeTemplateCode(code);
  return templates.firstWhere((t) => t.code == normalized, orElse: () => templates.first);
}

