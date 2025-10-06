import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/pdf_service.dart';
import '../../core/templates.dart';
import 'new_inspection_wizard.dart';

class InspectionDetailPage extends ConsumerWidget {
  final Map<String, dynamic> inspection;
  const InspectionDetailPage({super.key, required this.inspection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = inspection['nombre_comercial'] ?? '—';
    final radicado = inspection['radicado'] ?? '—';
    final fecha = inspection['fecha_inspeccion'] ?? '—';
    final tipo = inspection['tipo_inspeccion'] ?? '—';

    final resultado = inspection['resultado'] ?? {};

    int _toInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      return int.tryParse(value.toString()) ?? 0;
    }

    final puntaje = _toInt(resultado['puntaje_total']);
    final aprobado = resultado['aprobado'] ?? false;
    final minimo = _toInt(resultado['puntaje_minimo']);
    final template = templateByCode(tipo.toString());
    final maximo = resultado.containsKey('puntaje_maximo')
        ? _toInt(resultado['puntaje_maximo'])
        : template.maxScore;

    final modules = (inspection['modules'] ?? []) as List;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Inspección'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => NewInspectionWizard(
                    existing: Map<String, dynamic>.from(inspection),
                    inspectionId: inspection['id']?.toString(),
                  ),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                final bytes = await PdfService.buildInspectionPdf(
                  base: inspection,
                  modules: List<Map<String, dynamic>>.from(modules),
                  totalScore: puntaje,
                  passingScore: minimo,
                  maxScore: maximo,
                  aprobado: aprobado,
                );
                await Printing.sharePdf(
                    bytes: bytes, filename: 'informe_${radicado}.pdf');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: scheme.error,
                    content: Text('Error PDF: $e'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Radicado: $radicado'),
          Text('Fecha: $fecha'),
          Text('Tipo: $tipo'),
          Text('Comercio: $nombre'),
          const Divider(),
          Text('Puntaje: $puntaje / $maximo (mínimo: $minimo)'),
          Text(
            aprobado ? 'APROBADO ✅' : 'NO APROBADO ❌',
            style: TextStyle(
              color: aprobado ? scheme.primary : scheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Text('Módulos:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final mod in modules) ...[
            Text(mod['titulo'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final item in (mod['items'] ?? []) as List) ...[
              Text('- ${item['pregunta_texto']}: ${item['respuesta']} (${item['puntaje']} pts)'),
              if ((item['fotos'] ?? []).isNotEmpty)
                Wrap(
                  children: (item['fotos'] as List).map((f) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(f['url'], height: 60),
                    );
                  }).toList(),
                ),
              const Divider(),
            ]
          ],
        ],
      ),
    );
  }
}



