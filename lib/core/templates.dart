class Question {
  final String id;
  final String text;
  final int points; // puntos si cumple
  const Question({required this.id, required this.text, required this.points});
}

class TemplateDef {
  final String code; // 'pequeno', 'grande', ...
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
    code: 'pequeno',
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
    code: 'grande',
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
    code: 'estacion',
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

TemplateDef templateByCode(String code) {
  return templates.firstWhere((t) => t.code == code, orElse: () => templates.first);
}

