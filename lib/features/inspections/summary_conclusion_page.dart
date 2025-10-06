import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/pdf_service.dart';
import '../../core/providers.dart';

class SummaryConclusionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> baseData;
  final String tipoInspeccion;
  final List<Map<String, dynamic>> modulesData;
  final int passingScore;
  final int maxScore;
  final int totalScore;
  final bool aprobado;

  const SummaryConclusionPage({
    super.key,
    required this.baseData,
    required this.tipoInspeccion,
    required this.modulesData,
    required this.passingScore,
    required this.maxScore,
    required this.totalScore,
    required this.aprobado,
  });

  @override
  ConsumerState<SummaryConclusionPage> createState() =>
      _SummaryConclusionPageState();
}

class _SummaryConclusionPageState
    extends ConsumerState<SummaryConclusionPage> {
  bool _saving = false;

  Future<void> _guardarInspeccion() async {
    setState(() => _saving = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser!;
      final aprobado = widget.aprobado;

      final payload = {
        'inspector_id': user.id,
        'radicado': widget.baseData['radicado'],
        'fecha_inspeccion': widget.baseData['fecha_inspeccion'],
        'nombre_comercial': widget.baseData['nombre_comercial'],
        'representante_legal': widget.baseData['representante_legal'],
        'direccion_rut': widget.baseData['direccion_rut'],
        'celular_rut': widget.baseData['celular_rut'],
        'acompanante': widget.baseData['acompanante'] ?? '',
        'foto_fachada_url': widget.baseData['foto_fachada_url'],
        'visita_anterior': widget.baseData['visita_anterior'],
        'tipo_inspeccion': widget.tipoInspeccion,
        'modules': widget.modulesData,
        'resultado': {
          'puntaje_total': widget.totalScore,
          'puntaje_maximo': widget.maxScore,
          'aprobado': aprobado,
        },
      };

      await supabase.from('inspections').insert(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspección guardada ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generarPdf() async {
    try {
      final bytes = await PdfService.buildInspectionPdf(
        base: widget.baseData,
        modules: widget.modulesData,
        totalScore: widget.totalScore,
        passingScore: widget.passingScore,
        maxScore: widget.maxScore,
        aprobado: widget.aprobado,
      );
      await Printing.sharePdf(
          bytes: bytes, filename: 'informe_inspeccion_cbvsa.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
    }
  }

  String _conclusionTexto(bool aprobado, String nombre, String direccion) {
    if (aprobado) {
      return 'Se concluye que los aspectos evaluados en el establecimiento '
          '$nombre, ubicado en $direccion, SON FAVORABLES Y CUENTA con los requisitos mínimos '
          'para el concepto favorable en materia de seguridad humana y protección contra incendios.';
    } else {
      return 'Se concluye que los aspectos evaluados en el establecimiento '
          '$nombre, ubicado en $direccion, NO SON FAVORABLES Y NO CUENTA con los requisitos mínimos '
          'para el concepto favorable en materia de seguridad humana y protección contra incendios.';
    }
  }

  String _vigenciaTexto(bool aprobado) {
    if (aprobado) {
      return 'Para concepto favorable — Este certificado cuenta con una vigencia de un (1) año.';
    } else {
      return 'Para concepto no favorable — De acuerdo con el artículo 210 del reglamento administrativo, '
          'operativo, técnico y académico de los bomberos de Colombia, el plazo para subsanar los requerimientos '
          'no podrá exceder de 30 días calendario contados desde la entrega del informe de inspección.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (widget.baseData['nombre_comercial'] ?? '') as String;
    final direccion = (widget.baseData['direccion_rut'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen y Conclusión (Hoja 3)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ PUNTAJE Y ESTADO
          Text(
            'Puntaje total: ${widget.totalScore} / Mínimo requerido: ${widget.passingScore}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(widget.aprobado ? 'APROBADO ✅' : 'NO APROBADO ❌'),
            backgroundColor:
                widget.aprobado ? Colors.green[100] : Colors.red[100],
          ),
          const SizedBox(height: 16),

          // ✅ CONCLUSIÓN
          Text('Conclusión',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Text(_conclusionTexto(widget.aprobado, nombre, direccion)),
          const SizedBox(height: 16),

          // ✅ VIGENCIA
          Text('Vigencia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 8),
          Text(_vigenciaTexto(widget.aprobado)),
          const SizedBox(height: 24),

          // ✅ RESUMEN DE MÓDULOS Y PREGUNTAS
          Text('Resumen de módulos y observaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 10),

          for (final module in widget.modulesData) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module['titulo'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    for (final item in module['items']) ...[
                      Text(
                        '• ${item['pregunta_texto']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Respuesta: '),
                          Text(
                            item['respuesta'] == 'yes'
                                ? 'Sí / Cumple'
                                : item['respuesta'] == 'no'
                                    ? 'No cumple'
                                    : 'No aplica',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text('Puntaje: ${item['puntaje']}'),
                      if ((item['observacion'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Observación: ${item['observacion']}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      if ((item['fotos'] as List).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Text('Fotos:'),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final f in (item['fotos'] as List))
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Image.network(f['url']),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    f['url'],
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const Divider(),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _guardarInspeccion,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Guardando...' : 'Guardar inspección'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generarPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generar PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

