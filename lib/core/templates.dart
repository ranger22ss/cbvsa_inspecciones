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
}

const templates = <TemplateDef>[
  TemplateDef(
    code: 'comercio_pequeno',
    name: 'Comercio pequeño',
    passingScore: 70,
    questions: [
      Question(id: 'extintores', text: '¿Extintores señalizados y con carga vigente?', points: 15),
      Question(id: 'salida',     text: '¿Salida de emergencia libre de obstáculos?', points: 20),
      Question(id: 'inst_elec',  text: '¿Instalación eléctrica en buen estado?',   points: 20),
      Question(id: 'kit_prim',   text: '¿Botiquín de primeros auxilios disponible?', points: 15),
      Question(id: 'capacit',    text: '¿Personal capacitado en evacuación?',      points: 10),
    ],
  ),
  TemplateDef(
    code: 'comercio_grande',
    name: 'Comercio grande',
    passingScore: 80,
    questions: [
      Question(id: 'extintores', text: '¿Extintores suficientes y mantenidos?', points: 15),
      Question(id: 'hidrantes',  text: '¿Hidrantes internos operativos?',       points: 15),
      Question(id: 'rutas',      text: '¿Rutas de evacuación señalizadas?',     points: 20),
      Question(id: 'alarmas',    text: '¿Sistema de alarma funciona?',          points: 15),
      Question(id: 'aforo',      text: '¿Control de aforo y salidas adecuadas?',points: 15),
    ],
  ),
  TemplateDef(
    code: 'estacion_servicio',
    name: 'Estación de servicio',
    passingScore: 85,
    questions: [
      Question(id: 'tierra',     text: '¿Sistemas de puesta a tierra certificados?', points: 20),
      Question(id: 'derrame',    text: '¿Kit antiderrames disponible?',              points: 20),
      Question(id: 'senial',     text: '¿Señalización de seguridad completa?',       points: 15),
      Question(id: 'ext_esp',    text: '¿Extintores y espuma adecuados?',            points: 20),
      Question(id: 'zonas',      text: '¿Zonas peligrosas demarcadas?',              points: 10),
    ],
  ),
  TemplateDef(
    code: 'industria',
    name: 'Industria',
    passingScore: 90,
    questions: [
      Question(id: 'plan',       text: '¿Plan de emergencias actualizado?',      points: 20),
      Question(id: 'epi',        text: '¿EPP adecuado para las tareas?',         points: 15),
      Question(id: 'maquinas',   text: '¿Guardas y paros de emergencia?',        points: 20),
      Question(id: 'almacen',    text: '¿Almacenamiento de químicos correcto?',  points: 20),
      Question(id: 'capacit',    text: '¿Capacitaciones registradas?',           points: 15),
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
    case 'estacion_servicio':
    case 'estacionservicio':
    case 'estacion_de_servicio':
    case 'estacion':
    case 'gasolinera':
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

