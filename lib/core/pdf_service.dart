import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Genera el PDF completo de la inspección
  static Future<Uint8List> buildInspectionPdf({
    required Map<String, dynamic> base,
    required List<Map<String, dynamic>> modules,
    required int totalScore,
    required int passingScore,
    required bool aprobado,
  }) async {
    final inspection = _InspectionData.fromRaw(
      base: base,
      modules: modules,
      totalScore: totalScore,
      passingScore: passingScore,
      aprobado: aprobado,
    );

    final fachadaImage = await _loadNetworkImage(inspection.fotoFachadaUrl);
    final photoRows = await _buildPhotoRows(inspection.modules);

    final pdf = pw.Document();

    final acompanantePhrase = inspection.acompanante.isNotEmpty
        ? ' en compañía de ${inspection.acompanante}'
        : '';
    final fechaPhrase = inspection.formattedDate.isNotEmpty
        ? ' el ${inspection.formattedDate}'
        : '';

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
              pw.Text(inspection.nombreComercial.toUpperCase()),
              pw.Text(inspection.representanteLegal),
              pw.Text(inspection.direccion),
              if (inspection.celular.isNotEmpty) pw.Text(inspection.celular),
              pw.SizedBox(height: 10),
              pw.Text('San Alberto - Cesar'),
              pw.SizedBox(height: 20),
              pw.Text('Asunto: Informe de inspección protección contra incendios y seguridad humana.'),
              pw.SizedBox(height: 20),
              pw.Text('Cordial saludo respetado/a ${inspection.representanteLegal},'),
              pw.SizedBox(height: 10),
              pw.Text(
                'En atención a su comunicado mediante el cual solicita inspección ocular a través del radicado #${inspection.radicado} a ${inspection.nombreComercial}, '
                'ubicado en la ${inspection.direccion}, el cuerpo de bomberos se permite manifestar las observaciones y recomendaciones encontradas en el recorrido realizado, '
                'de acuerdo al artículo 42 de la Ley 1575 de 2012 “Ley general de bomberos de Colombia”.',
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

    // ---------- HOJA 2 ----------
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('1. Ubicación del establecimiento'),
          pw.Text(
            'El establecimiento ${inspection.nombreComercial} se encuentra ubicado en ${inspection.direccion}.',
          ),
          pw.SizedBox(height: 10),
          pw.Text('Foto fachada:'),
          pw.SizedBox(height: 10),
          if (fachadaImage != null)
            pw.Image(fachadaImage, height: 140, fit: pw.BoxFit.cover)
          else
            pw.Container(
              height: 120,
              color: PdfColors.grey300,
              alignment: pw.Alignment.center,
              child: pw.Text('Sin imagen disponible'),
            ),
          pw.SizedBox(height: 20),
          pw.Text('2. Recomendaciones visita anterior y antecedentes del establecimiento'),
          pw.Table.fromTextArray(
            headers: const ['Pregunta', 'Sí', 'No'],
            data: [
              [
                'Se subsanaron observaciones de la inspección anterior',
                inspection.visitaAnterior.subsanadasObsPrevias ? 'X' : '',
                inspection.visitaAnterior.subsanadasObsPrevias ? '' : 'X',
              ],
              [
                'Se presentaron emergencias en el último año',
                inspection.visitaAnterior.emergenciasUltimoAnio ? 'X' : '',
                inspection.visitaAnterior.emergenciasUltimoAnio ? '' : 'X',
              ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('3. Observaciones sobre condiciones de seguridad humana y protección contra incendios'),
          for (final module in inspection.modules) ...[
            pw.SizedBox(height: 15),
            pw.Text(
              module.titulo,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            if (module.items.isNotEmpty)
              pw.Table.fromTextArray(
                headers: const ['ITEM', 'Recomendación'],
                data: [
                  for (var i = 0; i < module.items.length; i++)
                    [
                      (i + 1).toString(),
                      module.items[i].recomendacion.isNotEmpty
                          ? module.items[i].recomendacion
                          : module.items[i].preguntaTexto,
                    ],
                ],
              )
            else
              pw.Text('Sin observaciones registradas para este módulo.'),
          ],
        ],
      ),
    );

    // ---------- HOJA 3/4 (Conclusión y Vigencia) ----------
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('4. Conclusión', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(
              'Que los aspectos inspeccionados al establecimiento ${inspection.nombreComercial}, ubicado en la ${inspection.direccion} '
              '${inspection.aprobado ? "SON FAVORABLES Y CUENTA" : "NO SON FAVORABLES Y NO CUENTA"} '
              'con los requisitos mínimos en sistemas de seguridad humana y protección contra incendios exigidos por la normativa.',
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
            pw.Text('Puntaje total obtenido: ${inspection.totalScore} / ${inspection.passingScore}'),
            pw.Text(
              inspection.aprobado ? 'Resultado: APROBADO' : 'Resultado: NO APROBADO',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: inspection.aprobado ? PdfColors.green : PdfColors.red,
              ),
            ),
          ],
        ),
      ),
    );

    // ---------- HOJA FINAL (Registro fotográfico) ----------
    if (photoRows.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('6. Registro fotográfico', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Hallazgo'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Imagen'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Observaciones y/o Recomendaciones'),
                    ),
                  ],
                ),
                for (final row in photoRows)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(row.hallazgo),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: row.imageProvider != null
                            ? pw.Image(
                                row.imageProvider!,
                                height: 80,
                                fit: pw.BoxFit.cover,
                              )
                            : pw.Container(
                                height: 80,
                                alignment: pw.Alignment.center,
                                color: PdfColors.grey300,
                                child: pw.Text('Sin imagen'),
                              ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(row.observacion),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              inspection.inspector.nombre,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  static Future<pw.ImageProvider?> _loadNetworkImage(String? url) async {
    if (url == null || url.isEmpty) {
      return null;
    }
    try {
      return await networkImage(url);
    } catch (_) {
      return null;
    }
  }

  static Future<List<_PhotoRow>> _buildPhotoRows(List<_ModuleData> modules) async {
    final rows = <_PhotoRow>[];
    for (final module in modules) {
      for (final item in module.items) {
        for (final foto in item.fotos) {
          final bytes = await _loadNetworkImage(foto.url);
          rows.add(
            _PhotoRow(
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
  final bool aprobado;

  String get formattedDate => fechaTexto;

  factory _InspectionData.fromRaw({
    required Map<String, dynamic> base,
    required List<Map<String, dynamic>> modules,
    required int totalScore,
    required int passingScore,
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
      items: rawItems.map((item) => _ModuleItemData.fromMap(item as Map<String, dynamic>)).toList(),
    );
  }
}

class _ModuleItemData {
  _ModuleItemData({
    required this.preguntaTexto,
    required this.recomendacion,
    required this.fotos,
  });

  final String preguntaTexto;
  final String recomendacion;
  final List<_FotoData> fotos;

  static _ModuleItemData fromMap(Map<String, dynamic> map) {
    final rawFotos = (map['fotos'] as List?) ?? const [];
    String _extractRecomendacion(Map<String, dynamic> json) {
      final candidates = [
        json['recomendacion'],
        json['recomendaciones'],
        json['observacion'],
        json['respuesta'],
      ];
      return candidates
          .firstWhere(
            (element) => element is String && element.trim().isNotEmpty,
            orElse: () => '',
          )
          .toString();
    }

    return _ModuleItemData(
      preguntaTexto: (map['pregunta_texto'] ?? map['pregunta'] ?? '').toString(),
      recomendacion: _extractRecomendacion(map),
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
    required this.hallazgo,
    required this.imageProvider,
    required this.observacion,
  });

  final String hallazgo;
  final pw.ImageProvider? imageProvider;
  final String observacion;
}

