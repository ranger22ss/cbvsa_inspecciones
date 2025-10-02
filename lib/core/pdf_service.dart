import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Servicio para construir el PDF final de la inspección
class PdfService {
  static Future<Uint8List> buildInspectionPdf({
    required Map<String, dynamic> base,
    required List<Map<String, dynamic>> modules,
    required int totalScore,
    required int passingScore,
    required bool aprobado,
  }) async {
    final pdf = pw.Document();

    final nombre = (base['nombre_comercial'] ?? '') as String;
    final direccion = (base['direccion_rut'] ?? '') as String;
    final radicado = (base['radicado'] ?? '') as String;
    final fecha = (base['fecha_inspeccion'] ?? '') as String;

    // 🟢 Portada (Hoja 1)
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('CUERPO DE BOMBEROS VOLUNTARIOS DE SAN ALBERTO, CESAR',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 24),
            pw.Text('INFORME DE INSPECCIÓN',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 24),
            pw.Text('Radicado: $radicado'),
            pw.Text('Fecha: $fecha'),
            pw.SizedBox(height: 12),
            pw.Text('Nombre comercial: $nombre'),
            pw.Text('Dirección: $direccion'),
          ],
        ),
      ),
    );

    // 🟠 Evaluación por módulos (Hoja 2)
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text('Evaluación por Módulos',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            for (final mod in modules) ...[
              pw.Text(mod['titulo'] ?? '',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Pregunta', 'Respuesta', 'Puntaje'],
                data: [
                  for (final q in mod['items'])
                    [
                      q['pregunta_texto'] ?? '',
                      q['respuesta'] ?? '',
                      (q['puntaje'] ?? 0).toString(),
                    ]
                ],
              ),
              pw.SizedBox(height: 16),
            ],
          ];
        },
      ),
    );

    // 🔵 Resumen y conclusión (Hoja 3)
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resumen y Conclusión',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Puntaje obtenido: $totalScore / Mínimo requerido: $passingScore'),
              pw.SizedBox(height: 8),
              pw.Text(aprobado ? 'APROBADO ✅' : 'NO APROBADO ❌',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: aprobado ? PdfColors.green : PdfColors.red,
                  )),
              pw.SizedBox(height: 16),
              pw.Text(aprobado
                  ? 'Se concluye que los aspectos evaluados en el establecimiento '
                    '$nombre ubicado en $direccion SON FAVORABLES y CUMPLE con los requisitos.'
                  : 'Se concluye que los aspectos evaluados en el establecimiento '
                    '$nombre ubicado en $direccion NO SON FAVORABLES y NO CUMPLE con los requisitos.'),
              pw.SizedBox(height: 16),
              pw.Text('Vigencia:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(aprobado
                  ? 'Para concepto favorable – Este certificado cuenta con una vigencia de un (1) año.'
                  : 'Para concepto no favorable – El plazo para subsanar los requerimientos no podrá exceder de 30 días calendario.'),
            ],
          );
        },
      ),
    );

    // 🟣 Registro fotográfico (Hoja 4)
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final rows = <List<String>>[];
          for (final mod in modules) {
            for (final q in mod['items']) {
              final fotos = (q['fotos'] as List?) ?? [];
              for (final f in fotos) {
                rows.add([
                  q['pregunta_texto'] ?? '',
                  f['url'] ?? '',
                  f['observacion'] ?? '',
                ]);
              }
            }
          }

          if (rows.isEmpty) {
            return [pw.Text('No se registraron fotografías.')];
          }

          return [
            pw.Text('Registro Fotográfico',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Pregunta', 'Foto (URL)', 'Observación'],
              data: rows,
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
