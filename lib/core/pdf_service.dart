import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

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
    final fecha = (base['fecha_inspeccion'] ?? '') as String;
    final radicado = (base['radicado'] ?? '') as String;
    final representante = (base['representante_legal'] ?? '') as String;
    final celular = (base['celular_rut'] ?? '') as String;
    final acompanante = (base['acompanante'] ?? '') as String;
    final fotoFachada = (base['foto_fachada_url'] ?? '') as String;

    final visita = Map<String, dynamic>.from(base['visita_anterior'] ?? const {});

    // Hoja 1 – Portada
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Informe de Inspección', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 8),
          _kv('Fecha', fecha),
          _kv('Nombre comercial', nombre),
          _kv('Representante legal', representante),
          _kv('Dirección', direccion),
          _kv('Celular', celular),
          _kv('# Radicado', radicado),
          _kv('Acompañante', acompanante),
          pw.SizedBox(height: 16),
          pw.Text('Elaborado por: (inspector) – Cuerpo de Bomberos Voluntario de San Alberto Cesar.'),
          pw.Spacer(),
          pw.Text('Firma de MARITZA BARRIONUEVO QUIÑONEZ – REPRESENTANTE LEGAL'),
        ],
      ),
    );

    // Hoja 2 – Ubicación / Visita anterior / Foto fachada
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
        build: (ctx) => [
          pw.Text('Ubicación', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('El establecimiento $nombre se encuentra en $direccion.'),
          pw.SizedBox(height: 12),
          pw.Text('Visita anterior', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              _row2('¿Se subsanaron observaciones previas?', _siNo(visita['subsanadas_obs_previas'] == true)),
              _row2('¿Emergencias en el último año?', _siNo(visita['emergencias_ultimo_anio'] == true)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Foto de fachada', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (fotoFachada.isNotEmpty)
            pw.Container(
              height: 200,
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              child: pw.Center(child: pw.Text(fotoFachada, style: const pw.TextStyle(fontSize: 10))),
            )
          else
            pw.Text('No adjunta'),
        ],
      ),
    );

    // Hojas de observaciones por módulos (solo los ítems con observación)
    final obsTables = <pw.Widget>[];
    for (final mod in modules) {
      final titulo = (mod['titulo'] ?? '') as String;
      final items = List<Map<String, dynamic>>.from(mod['items'] ?? const []);
      final filas = <pw.TableRow>[];
      int idx = 1;
      for (final it in items) {
        final fotos = List<Map<String, dynamic>>.from(it['fotos'] ?? const []);
        for (final f in fotos) {
          final obs = (f['observacion'] ?? '') as String;
          if (obs.isNotEmpty) {
            filas.add(_row3('$idx', (it['pregunta_texto'] ?? '') as String, obs));
            idx++;
          }
        }
      }
      if (filas.isNotEmpty) {
        obsTables.addAll([
          pw.SizedBox(height: 8),
          pw.Text(titulo, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('Item', bold: true),
                  _cell('Pregunta/Hallazgo', bold: true),
                  _cell('Recomendación', bold: true),
                ],
              ),
              ...filas,
            ],
          ),
        ]);
      }
    }
    if (obsTables.isNotEmpty) {
      pdf.addPage(pw.MultiPage(pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)), build: (ctx) => obsTables));
    }

    // Conclusión y Vigencia
    final concl = aprobado
        ? '…los aspectos SON FAVORABLES Y CUENTA con los requisitos mínimos…'
        : '…los aspectos NO SON FAVORABLES Y NO CUENTA con los requisitos mínimos…';
    final vig = aprobado
        ? 'Para concepto favorable – Este certificado cuenta con una vigencia de un (1) año.'
        : 'Para concepto no favorable – De acuerdo con el artículo 210… 30 días calendario desde la entrega del informe.';
    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
        build: (ctx) => [
          pw.Text('Resumen', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          _kv('Puntaje total', '$totalScore'),
          _kv('Mínimo requerido', '$passingScore'),
          _kv('Estado', aprobado ? 'APROBADO' : 'NO APROBADO'),
          pw.SizedBox(height: 12),
          pw.Text('Conclusión', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Se concluye que en $nombre ubicado en $direccion $concl'),
          pw.SizedBox(height: 12),
          pw.Text('Vigencia', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(vig),
        ],
      ),
    );

    // Registro Fotográfico (todas las fotos)
    final fotoRows = <pw.TableRow>[];
    for (final mod in modules) {
      final items = List<Map<String, dynamic>>.from(mod['items'] ?? const []);
      for (final it in items) {
        final txt = (it['pregunta_texto'] ?? '') as String;
        final fotos = List<Map<String, dynamic>>.from(it['fotos'] ?? const []);
        for (final f in fotos) {
          final url = (f['url'] ?? '') as String;
          final obs = (f['observacion'] ?? '') as String;
          fotoRows.add(
            pw.TableRow(
              children: [
                _cell(txt),
                // Nota: sin descargar imagen, mostramos URL dentro de un recuadro para referencia
                pw.Container(
                  height: 80,
                  alignment: pw.Alignment.center,
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Text(url, style: const pw.TextStyle(fontSize: 8)),
                ),
                _cell(obs),
              ],
            ),
          );
        }
      }
    }
    if (fotoRows.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(32)),
          build: (ctx) => [
            pw.Text('Registro Fotográfico', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Pregunta/Hallazgo', bold: true),
                    _cell('Imagen (URL)', bold: true),
                    _cell('Observaciones/Recomendaciones', bold: true),
                  ],
                ),
                ...fotoRows,
              ],
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _kv(String k, String v) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(v, textAlign: pw.TextAlign.right)),
        ],
      );

  static String _siNo(bool v) => v ? 'Sí' : 'No';

  static pw.TableRow _row2(String c1, String c2) => pw.TableRow(
        children: [_cell(c1), _cell(c2)],
      );

  static pw.TableRow _row3(String c1, String c2, String c3) => pw.TableRow(
        children: [_cell(c1), _cell(c2), _cell(c3)],
      );

  static pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
}
