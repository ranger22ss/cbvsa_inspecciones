import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfService {
  /// Genera el PDF completo de la inspección
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
    final fecha = (base['fecha_inspeccion'] ?? '').toString();
    final representante = (base['representante_legal'] ?? '') as String;
    final celular = (base['celular_rut'] ?? '') as String;
    final acompanante = (base['acompanante'] ?? '') as String;
    final fotoFachada = (base['foto_fachada_url'] ?? '') as String?;
    final visita = base['visita_anterior'] as Map<String, dynamic>? ?? {};

    // 🔹 Portada / Hoja 1
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INFORME DE INSPECCIÓN', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Radicado: $radicado'),
            pw.Text('Fecha de inspección: $fecha'),
            pw.Text('Nombre comercial: $nombre'),
            pw.Text('Representante legal: $representante'),
            pw.Text('Dirección: $direccion'),
            pw.Text('Celular: $celular'),
            pw.Text('Acompañante: $acompanante'),
            if (fotoFachada != null && fotoFachada.isNotEmpty) pw.SizedBox(height: 12),
            if (fotoFachada != null && fotoFachada.isNotEmpty)
              pw.Text('Foto fachada (ver anexo en digital)'),
          ],
        ),
      ),
    );

    // 🔹 Hoja 2 – Visita anterior
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('VISITA ANTERIOR', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text('¿Se subsanaron observaciones previas?: '
                '${visita['subsanadas_obs_previas'] == true ? 'Sí' : 'No'}'),
            pw.Text('¿Hubo emergencias en el último año?: '
                '${visita['emergencias_ultimo_anio'] == true ? 'Sí' : 'No'}'),
          ],
        ),
      ),
    );

    // 🔹 Hoja 3 – Conclusión
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CONCLUSIÓN', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Text('Puntaje total: $totalScore / $passingScore'),
            pw.Text(aprobado ? 'APROBADO ✅' : 'NO APROBADO ❌',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: aprobado ? PdfColors.green : PdfColors.red,
                )),
            pw.SizedBox(height: 20),
            pw.Text(aprobado
                ? 'Los aspectos evaluados en el establecimiento $nombre ubicado en $direccion SON FAVORABLES Y CUENTA con los requisitos mínimos para el concepto favorable.'
                : 'Los aspectos evaluados en el establecimiento $nombre ubicado en $direccion NO SON FAVORABLES Y NO CUENTA con los requisitos mínimos para el concepto favorable.'),
            pw.SizedBox(height: 16),
            pw.Text(aprobado
                ? 'Vigencia: 1 año (concepto favorable).'
                : 'Vigencia: Para concepto no favorable, el plazo para subsanación no podrá exceder de 30 días calendario desde la entrega del informe.'),
          ],
        ),
      ),
    );

    // 🔹 Hoja 4 – Registro fotográfico (solo preguntas con fotos)
    final fotosConPreguntas = <Map<String, dynamic>>[];
    for (final mod in modules) {
      final items = (mod['items'] ?? []) as List;
      for (final it in items) {
        final fotos = (it['fotos'] ?? []) as List;
        if (fotos.isNotEmpty) {
          fotosConPreguntas.add({
            'pregunta': it['pregunta_texto'] ?? it['text'],
            'fotos': fotos,
          });
        }
      }
    }

    if (fotosConPreguntas.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          build: (ctx) => [
            pw.Text('REGISTRO FOTOGRÁFICO', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...fotosConPreguntas.map((row) {
              final pregunta = row['pregunta'] as String;
              final fotos = (row['fotos'] as List).cast<Map<String, dynamic>>();
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(pregunta, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: fotos.map((f) {
                      final obs = f['observacion'] ?? '';
                      return pw.Container(
                        width: 180,
                        child: pw.Column(
                          children: [
                            pw.Container(
                              height: 100,
                              width: 160,
                              color: PdfColors.grey300,
                              alignment: pw.Alignment.center,
                              child: pw.Text('Foto (digital)', style: const pw.TextStyle(fontSize: 10)),
                            ),
                            if (obs.toString().isNotEmpty) pw.Text(obs, style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  pw.Divider(),
                ],
              );
            }),
          ],
        ),
      );
    }

    return pdf.save();
  }
}

