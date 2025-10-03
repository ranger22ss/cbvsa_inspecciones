import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/pdf_service.dart';
import '../../core/providers.dart'; // <- supabaseProvider

class SummaryConclusionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> baseData;                 // Hoja 1
  final String tipoInspeccion;                         // tipo seleccionado
  final List<Map<String, dynamic>> modules;            // módulos armados en Hoja 2
  final int passingScore;
  final int totalScore;
  final bool aprobado;

  const SummaryConclusionPage({
    super.key,
    required this.baseData,
    required this.tipoInspeccion,
    required this.modules,
    required this.passingScore,
    required this.totalScore,
    required this.aprobado,
  });

  @override
  ConsumerState<SummaryConclusionPage> createState() =>
      _SummaryConclusionPageState();
}

class _SummaryConclusionPageState extends ConsumerState<SummaryConclusionPage> {
  bool _saving = false;

  Future<void> _guardarInspeccion() async {
    setState(() => _saving = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser!;
      final aprobado = widget.aprobado;

      // Payload final con todos los datos
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
        'visita_anterior': widget.baseData['visita_anterior'], // jsonb
        'tipo_inspeccion': widget.tipoInspeccion,
        'modules': widget.modules, // jsonb
        'resultado': {
          'puntaje_total': widget.totalScore,   // 👈 ahora sí el real
          'aprobado': aprobado,
          'puntaje_minimo': widget.passingScore,
        },
      };

      await supabase.from('inspections').insert(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspección guardada ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generarPdf() async {
    try {
      final bytes = await PdfService.buildInspectionPdf(
        base: widget.baseData,
        modules: widget.modules,
        totalScore: widget.totalScore,
        passingScore: widget.passingScore,
        aprobado: widget.aprobado,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'informe_inspeccion.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando PDF: $e')),
      );
    }
  }

  String _conclusionTexto(bool aprobado, String nombre, String direccion) {
    if (aprobado) {
      return 'Se concluye que los aspectos evaluados en el establecimiento '
          '$nombre ubicado en $direccion SON FAVORABLES Y CUENTA con los requisitos mínimos para el concepto favorable.';
    } else {
      return 'Se concluye que los aspectos evaluados en el establecimiento '
          '$nombre ubicado en $direccion NO SON FAVORABLES Y NO CUENTA con los requisitos mínimos para el concepto favorable.';
    }
  }

  String _vigenciaTexto(bool aprobado) {
    if (aprobado) {
      return 'Para concepto favorable – Este certificado cuenta con una vigencia de un (1) año.';
    } else {
      return 'Para concepto no favorable – De acuerdo con el artículo 210 del reglamento administrativo, '
          'operativo, técnico y académico de los bomberos de Colombia, el plazo para la subsanación de los requerimientos '
          'contenidos en este informe no podrá exceder de los 30 días calendario contados desde la entrega del informe de inspección.';
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
          Text(
            'Puntaje total: ${widget.totalScore} / Mínimo: ${widget.passingScore}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(widget.aprobado ? 'APROBADO' : 'NO APROBADO'),
            backgroundColor: widget.aprobado ? Colors.green[100] : Colors.red[100],
          ),
          const SizedBox(height: 16),
          Text('Conclusión', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_conclusionTexto(widget.aprobado, nombre, direccion)),
          const SizedBox(height: 16),
          Text('Vigencia', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_vigenciaTexto(widget.aprobado)),
          const SizedBox(height: 24),

          // Botones de acción
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



