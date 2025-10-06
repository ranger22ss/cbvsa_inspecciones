// ignore_for_file: unused_import

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class PdfService {
  /// Genera el PDF completo de la inspección
  static Future<Uint8List> buildInspectionPdf({
    required Map<String, dynamic> base,
    required List<Map<String, dynamic>> modules,
    required int totalScore,
    required int passingScore,
    required int maxScore,
    required bool aprobado,
  }) async {
    final inspection = _InspectionData.fromRaw(
      base: base,
      modules: modules,
      totalScore: totalScore,
      passingScore: passingScore,
      maxScore: maxScore,
      aprobado: aprobado,
    );

    final fachadaBytes = await _loadNetworkImage(inspection.fotoFachadaUrl);
    final photoRows = await _buildPhotoRows(inspection.modules);

    final pdf = pw.Document();

    final acompanantePhrase = inspection.acompanante.isNotEmpty
        ? ' en compañía de ${inspection.acompanante}'
        : '';
    final fechaPhrase = inspection.formattedDate.isNotEmpty
        ? ' el ${inspection.formattedDate}'
        : '';

    pw.Widget buildSignatureBlock() {
      final nombre = inspection.inspector.nombre.isNotEmpty
          ? inspection.inspector.nombre.toUpperCase()
          : 'INSPECTOR';
      final rango = inspection.inspector.rango.isNotEmpty
          ? inspection.inspector.rango.toUpperCase()
          : 'INSPECTOR';
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  nombre,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  rango,
                  style: pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Cuerpo de Bomberos Voluntario de San Alberto Cesar',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      );
    }

    String formatAnswer(String value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return 'Sin respuesta registrada';
      switch (normalized) {
        case 'yes':
        case 'si':
          return 'Sí';
        case 'no':
          return 'No';
        case 'na':
        case 'n/a':
        case 'no aplica':
          return 'No aplica';
        case 'a':
          return 'Nivel A';
        case 'b':
          return 'Nivel B';
        case 'c':
          return 'Nivel C';
        default:
          return value.trim();
      }
    }

    String buildObservationText(_ModuleItemData item) {
      final buffer = <String>[];
      if (item.observacion.trim().isNotEmpty) {
        buffer.add(item.observacion.trim());
      }
      final photoObservations = item.fotos
          .map((foto) => foto.observacion.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (photoObservations.isNotEmpty) {
        buffer.addAll(photoObservations.map((obs) => '• $obs'));
      }
      if (buffer.isEmpty) {
        return 'Sin observaciones registradas.';
      }
      return buffer.join('\n');
    }

    pw.Widget buildQuestionCard(_ModuleItemData item) {
      final answerText = formatAnswer(item.respuesta);
      final observationText = buildObservationText(item);
      return pw.Container(
        width: double.infinity,
        margin: pw.EdgeInsets.symmetric(vertical: 6),
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey600, width: 0.7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Pregunta',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(item.preguntaTexto.isNotEmpty
                ? item.preguntaTexto
                : 'Pregunta sin título'),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Respuesta',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(answerText),
                      if (item.puntaje != null)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: 6),
                          child: pw.Text(
                            'Puntaje obtenido: ${item.puntaje}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Observación',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(observationText),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ---------- HOJA 1 ----------
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Oficio de radicación del Cuerpo de Bomberos del Municipio de San Alberto #${inspection.radicado}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                inspection.formattedDate.isNotEmpty
                    ? 'Municipio de San Alberto - Cesar, ${inspection.formattedDate}'
                    : 'Municipio de San Alberto - Cesar',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'REFERENTES',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(inspection.nombreComercial.toUpperCase()),
              pw.Text(inspection.representanteLegal),
              pw.Text(inspection.direccion),
              if (inspection.celular.isNotEmpty) pw.Text(inspection.celular),
              pw.SizedBox(height: 10),
              pw.Text('San Alberto - Cesar'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Asunto: Informe de inspección protección contra incendios y seguridad humana.',
              ),
              pw.SizedBox(height: 20),
              pw.Text('Cordial saludo respetado/a ${inspection.representanteLegal},'),
              pw.SizedBox(height: 10),
              pw.Text(
                'En atención a su comunicado mediante el cual solicita inspección ocular a través del radicado #${inspection.radicado} a ${inspection.nombreComercial}, '
                'ubicado en la ${inspection.direccion}, el Cuerpo de Bomberos se permite manifestar las observaciones y recomendaciones encontradas en el recorrido realizado, '
                'de acuerdo con el artículo 42 de la Ley 1575 de 2012 “Ley general de bomberos de Colombia”.',
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Como resultado de la visita desarrollada por el inspector ${inspection.inspector.nombre}'
                '$acompanantePhrase$fechaPhrase, se entrega el presente informe.',
              ),
              pw.SizedBox(height: 40),
              pw.Text('Cordialmente,'),
              pw.SizedBox(height: 20),
              pw.Text(
                'MARITZA BARRIONUEVO QUIÑONEZ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('REPRESENTANTE LEGAL'),
              pw.Spacer(),
              pw.Text(
                'Elaborado por: ${inspection.inspector.nombre} - ${inspection.inspector.rango} / Cuerpo de Bomberos Voluntario de San Alberto Cesar',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    // ---------- HOJA 2 Y SIGUIENTES (Información general y observaciones) ----------
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '1. Ubicación del establecimiento',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'El establecimiento ${inspection.nombreComercial} se encuentra ubicado en ${inspection.direccion}.',
                ),
                pw.SizedBox(height: 10),
                pw.Text('Foto fachada:'),
                pw.SizedBox(height: 10),
                if (fachadaBytes != null)
                  pw.ClipRRect(
                    horizontalRadius: 6,
                    verticalRadius: 6,
                    child: pw.Image(
                      pw.MemoryImage(fachadaBytes),
                      height: 140,
                      fit: pw.BoxFit.cover,
                    ),
                  )
                else
                  pw.Container(
                    height: 120,
                    color: PdfColors.grey300,
                    alignment: pw.Alignment.center,
                    child: pw.Text('Sin imagen disponible'),
                  ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '2. Recomendaciones visita anterior y antecedentes del establecimiento',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Tabla 1. Evaluación de requerimientos visitas anteriores'),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.7),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Requerimiento'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Sí'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('No'),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Se subsanaron observaciones de la inspección anterior',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            inspection.visitaAnterior.subsanadasObsPrevias ? 'X' : '',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            inspection.visitaAnterior.subsanadasObsPrevias ? '' : 'X',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text('Se presentaron emergencias en el último año'),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            inspection.visitaAnterior.emergenciasUltimoAnio ? 'X' : '',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            inspection.visitaAnterior.emergenciasUltimoAnio ? '' : 'X',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 20));

          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '3. Observaciones sobre condiciones de seguridad humana y protección contra incendios',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                for (final module in inspection.modules) ...[
                  pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(top: 16),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      module.titulo.isNotEmpty
                          ? module.titulo
                          : 'Módulo sin título',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  if (module.items.isNotEmpty)
                    ...module.items.map(buildQuestionCard)
                  else
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      child: pw.Text('Sin observaciones registradas para este módulo.'),
                    ),
                ],
              ],
            ),
          );

          return widgets;
        },
      ),
    );

    // ---------- HOJA 3 (Conclusión y Vigencia) ----------
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('4. Conclusión', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(
              'Que los aspectos inspeccionados al establecimiento ${inspection.nombreComercial}, ubicado en la ${inspection.direccion} '
              '${inspection.aprobado ? 'SON FAVORABLES Y CUENTA' : 'NO SON FAVORABLES Y NO CUENTA'} con los requisitos mínimos en sistemas de seguridad humana y protección contra incendios exigidos por la normativa colombiana.',
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'A su vez, ${inspection.nombreComercial} se compromete a acatar todas las recomendaciones emanadas por el Cuerpo de Bomberos Voluntarios del municipio de San Alberto – Cesar, '
              'en el entendido de que son acciones obligatorias para garantizar la protección integral de los bienes tangibles e intangibles y la vida de los ocupantes, visitantes y trabajadores del establecimiento.',
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Se sugiere al ${inspection.nombreComercial} complementar la visita realizada con la verificación del plan de emergencias, '
              'el mantenimiento de los sistemas instalados y la capacitación permanente del personal responsable de la seguridad humana y la protección contra incendios.',
            ),
            pw.SizedBox(height: 20),
            pw.Text('5. Vigencia', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (inspection.aprobado)
              pw.Text('Para concepto favorable. Este certificado cuenta con una vigencia de un (1) año.')
            else
              pw.Text(
                'Para concepto no favorable. De acuerdo con el artículo 210 del reglamento administrativo, operativo, técnico y académico de los bomberos de Colombia, '
                'el plazo para la subsanación de los requerimientos contenidos en este informe no podrá exceder de los 30 días calendario contados desde la entrega del informe de inspección.',
              ),
            pw.SizedBox(height: 20),
            pw.Text(
                'Puntaje total obtenido: ${inspection.totalScore} / ${inspection.maxScore} (mínimo: ${inspection.passingScore})'),
            pw.Text(
              inspection.aprobado ? 'Resultado: APROBADO' : 'Resultado: NO APROBADO',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: inspection.aprobado ? PdfColors.green : PdfColors.red,
              ),
            ),
            if (photoRows.isEmpty) ...[
              pw.Spacer(),
              buildSignatureBlock(),
            ],
          ],
        ),
      ),
    );

    // ---------- HOJAS FINALES (Registro fotográfico) ----------
    if (photoRows.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('6. Registro fotográfico', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.7),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Imagen',
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(6),
                      child: pw.Text('Observaciones del inspector'),
                    ),
                  ],
                ),
                for (final row in photoRows)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          children: [
                            pw.Image(
                              pw.MemoryImage(row.imageBytes),
                              height: 140,
                              fit: pw.BoxFit.cover,
                            ),
                            if (row.hallazgo.isNotEmpty) ...[
                              pw.SizedBox(height: 6),
                              pw.Text(
                                row.hallazgo,
                                style: const pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (row.modulo.isNotEmpty)
                              pw.Text(
                                row.modulo,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            if (row.observacion.trim().isNotEmpty)
                              pw.Text(
                                row.observacion.trim(),
                                style: const pw.TextStyle(fontSize: 10),
                              )
                            else
                              pw.Text(
                                'Sin observación registrada.',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            children: [
              pw.Spacer(),
              buildSignatureBlock(),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  static Future<Uint8List?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) {
      return null;
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<_PhotoRow>> _buildPhotoRows(List<_ModuleData> modules) async {
    final rows = <_PhotoRow>[];
    for (final module in modules) {
      for (final item in module.items) {
        for (final foto in item.fotos) {
          if (foto.url == null) continue;
          final bytes = await _loadNetworkImage(foto.url);
          if (bytes == null) continue;
          rows.add(
            _PhotoRow(
              modulo: module.titulo,
              hallazgo: item.preguntaTexto,
              imageBytes: bytes,
              observacion: foto.observacion,
            ),
          );
        }
      }
    }
    return rows;
  }
}

// ------------------ MODELOS INTERNOS ------------------

class _InspectionData {
  _InspectionData({
    required this.radicado,
    required this.fechaInspeccion,
    required this.fechaTexto,
    required this.nombreComercial,
    required this.representanteLegal,
    required this.direccion,
    required this.celular,
    required this.acompanante,
    required this.inspector,
    required this.fotoFachadaUrl,
    required this.visitaAnterior,
    required this.modules,
    required this.totalScore,
    required this.passingScore,
    required this.maxScore,
    required this.aprobado,
  });

  final String radicado;
  final DateTime? fechaInspeccion;
  final String fechaTexto;
  final String nombreComercial;
  final String representanteLegal;
  final String direccion;
  final String celular;
  final String acompanante;
  final _Inspector inspector;
  final String? fotoFachadaUrl;
  final _VisitaAnterior visitaAnterior;
  final List<_ModuleData> modules;
  final int totalScore;
  final int passingScore;
  final int maxScore;
  final bool aprobado;

  String get formattedDate => fechaTexto;

  factory _InspectionData.fromRaw({
    required Map<String, dynamic> base,
    required List<Map<String, dynamic>> modules,
    required int totalScore,
    required int passingScore,
    required int maxScore,
    required bool aprobado,
  }) {
    final inspectorMap = base['inspector'] as Map<String, dynamic>? ?? {};
    final fechaRaw = base['fecha_inspeccion'];
    DateTime? fecha;
    if (fechaRaw is String && fechaRaw.isNotEmpty) {
      try {
        fecha = DateTime.parse(fechaRaw).toLocal();
      } catch (_) {
        fecha = null;
      }
    }

    String fechaTexto = '';
    if (fecha != null) {
      final day = fecha.day.toString().padLeft(2, '0');
      final month = fecha.month.toString().padLeft(2, '0');
      final year = fecha.year.toString();
      fechaTexto = '$day/$month/$year';
    } else if (fechaRaw != null) {
      fechaTexto = fechaRaw.toString();
    }

    return _InspectionData(
      radicado: (base['radicado'] ?? '').toString(),
      fechaInspeccion: fecha,
      fechaTexto: fechaTexto,
      nombreComercial: (base['nombre_comercial'] ?? '').toString(),
      representanteLegal: (base['representante_legal'] ?? '').toString(),
      direccion: (base['direccion_rut'] ?? '').toString(),
      celular: (base['celular_rut'] ?? '').toString(),
      acompanante: (base['acompanante'] ?? '').toString(),
      inspector: _Inspector(
        nombre: (inspectorMap['nombre'] ?? inspectorMap['full_name'] ?? '').toString(),
        rango: (inspectorMap['rango'] ?? inspectorMap['rank'] ?? '').toString(),
      ),
      fotoFachadaUrl: (base['foto_fachada_url'] ?? '').toString().isEmpty
          ? null
          : (base['foto_fachada_url'] ?? '').toString(),
      visitaAnterior: _VisitaAnterior.fromMap(
        base['visita_anterior'] as Map<String, dynamic>? ?? {},
      ),
      modules: modules.map(_ModuleData.fromMap).toList(),
      totalScore: totalScore,
      passingScore: passingScore,
      maxScore: maxScore,
      aprobado: aprobado,
    );
  }
}

class _Inspector {
  _Inspector({required this.nombre, required this.rango});
  final String nombre;
  final String rango;
}

class _VisitaAnterior {
  _VisitaAnterior({
    required this.subsanadasObsPrevias,
    required this.emergenciasUltimoAnio,
  });

  final bool subsanadasObsPrevias;
  final bool emergenciasUltimoAnio;

  factory _VisitaAnterior.fromMap(Map<String, dynamic> map) {
    bool _toBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        return normalized == 'true' || normalized == '1' || normalized == 'si';
      }
      return false;
    }

    return _VisitaAnterior(
      subsanadasObsPrevias: _toBool(map['subsanadas_obs_previas']),
      emergenciasUltimoAnio: _toBool(map['emergencias_ultimo_anio']),
    );
  }
}

class _ModuleData {
  _ModuleData({required this.titulo, required this.items});
  final String titulo;
  final List<_ModuleItemData> items;

  static _ModuleData fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? const [];
    return _ModuleData(
      titulo: (map['titulo'] ?? '').toString(),
      items: rawItems
          .map((item) => _ModuleItemData.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _ModuleItemData {
  _ModuleItemData({
    required this.preguntaTexto,
    required this.respuesta,
    required this.observacion,
    required this.puntaje,
    required this.fotos,
  });

  final String preguntaTexto;
  final String respuesta;
  final String observacion;
  final int? puntaje;
  final List<_FotoData> fotos;

  static _ModuleItemData fromMap(Map<String, dynamic> map) {
    final rawFotos = (map['fotos'] as List?) ?? const [];
    String extractObservacion(Map<String, dynamic> json) {
      final candidates = [
        json['observacion'],
        json['observaciones'],
        json['recomendacion'],
        json['respuesta'],
      ];
      return candidates
          .firstWhere(
            (element) => element is String && element.trim().isNotEmpty,
            orElse: () => '',
          )
          .toString();
    }

    int? extractScore(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString());
    }

    return _ModuleItemData(
      preguntaTexto: (map['pregunta_texto'] ?? map['pregunta'] ?? '').toString(),
      respuesta: (map['respuesta'] ?? '').toString(),
      observacion: extractObservacion(map),
      puntaje: extractScore(map['puntaje']),
      fotos: rawFotos
          .map((foto) => _FotoData.fromMap((foto ?? {}) as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _FotoData {
  _FotoData({required this.url, required this.observacion});
  final String? url;
  final String observacion;

  static _FotoData fromMap(Map<String, dynamic> map) {
    final url = (map['url'] ?? map['path'] ?? '').toString();
    return _FotoData(
      url: url.isEmpty ? null : url,
      observacion: (map['observacion'] ?? '').toString(),
    );
  }
}

class _PhotoRow {
  _PhotoRow({
    required this.modulo,
    required this.hallazgo,
    required this.imageBytes,
    required this.observacion,
  });

  final String modulo;
  final String hallazgo;
  final Uint8List imageBytes;
  final String observacion;
}
