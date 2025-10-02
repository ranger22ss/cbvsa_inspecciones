class PhotoNote {
  final String url;
  final String? observacion;
  const PhotoNote({required this.url, this.observacion});

  Map<String, dynamic> toJson() => {
    'url': url,
    if (observacion != null && observacion!.isNotEmpty) 'observacion': observacion,
  };

  factory PhotoNote.fromJson(Map<String, dynamic> j) =>
      PhotoNote(url: j['url'] as String, observacion: j['observacion'] as String?);
}

class ModuleItem {
  final String preguntaId;
  final String preguntaTexto;
  final String respuesta; // "A|B|C|Sí|No|puntaje" o "yes|no|na" según plantilla
  final int puntaje;
  final List<PhotoNote> fotos;

  const ModuleItem({
    required this.preguntaId,
    required this.preguntaTexto,
    required this.respuesta,
    required this.puntaje,
    this.fotos = const [],
  });

  Map<String, dynamic> toJson() => {
    'pregunta_id': preguntaId,
    'pregunta_texto': preguntaTexto,
    'respuesta': respuesta,
    'puntaje': puntaje,
    'fotos': fotos.map((f) => f.toJson()).toList(),
  };

  factory ModuleItem.fromJson(Map<String, dynamic> j) => ModuleItem(
    preguntaId: j['pregunta_id'] as String,
    preguntaTexto: j['pregunta_texto'] as String,
    respuesta: j['respuesta'] as String,
    puntaje: (j['puntaje'] as num).toInt(),
    fotos: (j['fotos'] as List? ?? [])
        .map((e) => PhotoNote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class ModuleBlock {
  final String titulo;
  final List<ModuleItem> items;
  const ModuleBlock({required this.titulo, required this.items});

  Map<String, dynamic> toJson() =>
      {'titulo': titulo, 'items': items.map((e) => e.toJson()).toList()};

  factory ModuleBlock.fromJson(Map<String, dynamic> j) => ModuleBlock(
    titulo: j['titulo'] as String,
    items: (j['items'] as List? ?? [])
        .map((e) => ModuleItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class InspectionResult {
  final int puntajeTotal;
  final bool aprobado;
  const InspectionResult({required this.puntajeTotal, required this.aprobado});

  Map<String, dynamic> toJson() => {
    'puntaje_total': puntajeTotal,
    'aprobado': aprobado,
  };

  factory InspectionResult.fromJson(Map<String, dynamic> j) =>
      InspectionResult(
        puntajeTotal: (j['puntaje_total'] as num).toInt(),
        aprobado: j['aprobado'] as bool,
      );
}

