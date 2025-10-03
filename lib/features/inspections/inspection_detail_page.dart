import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/pdf_service.dart';

class InspectionDetailPage extends ConsumerWidget {
  final Map<String, dynamic> row;
  const InspectionDetailPage({super.key, required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = row['resultado'] as Map<String, dynamic>? ?? {};
    final aprobado = resultado['aprobado'] as bool? ?? false;
    final puntaje = resultado['puntaje_total'] ?? 0;
    final passing = _getPassingScore(row['tipo_inspeccion'] as String?);

    return Scaffold(
      appBar: AppBar(
        title: Text('Inspección: ${row['nombre_comercial'] ?? '—'}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Datos del establecimiento',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _dato('Radicado', row['radicado']),
          _dato('Fecha', row['fecha_inspeccion']),
          _dato('Nombre comercial', row['nombre_comercial']),
          _dato('Representante legal', row['representante_legal']),
          _dato('Dirección', row['direccion_rut']),
          _dato('Celular', row['celular_rut']),
          _dato('Acompañante', row['acompanante']),
          const Divider(),

          Text('Resultado',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Puntaje: $puntaje / Mínimo: $passing'),
          Chip(
            label: Text(aprobado ? 'APROBADO' : 'NO APROBADO'),
            backgroundColor: aprobado ? Colors.green[100] : Colors.red[100],
          ),
          const Divider(),

          Text('Módulos evaluados',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (row['modules'] != null)
            ...List.generate((row['modules'] as List).length, (m) {
              final mod = row['modules'][m] as Map<String, dynamic>;
              final items = (mod['items'] as List).cast<Map<String, dynamic>>();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mod['titulo'] ?? 'Módulo',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...items.map((q) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q['pregunta_texto'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text('Respuesta: ${q['respuesta']}'),
                              Text('Puntaje: ${q['puntaje']}'),
                              if ((q['fotos'] as List?)?.isNotEmpty ?? false)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (q['fotos'] as List)
                                      .map((f) => Image.network(
                                            (f as Map)['url'],
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                          ))
                                      .toList(),
                                ),
                              const Divider(),
                            ],
                          )),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // Botones acción
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      final bytes = await PdfService.buildInspectionPdf(
                        base: Map<String, dynamic>.from(row),
                        modules: (row['modules'] as List)
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList(),
                        totalScore: puntaje,
                        passingScore: passing,
                        aprobado: aprobado,
                      );
                      await Printing.sharePdf(
                          bytes: bytes, filename: 'informe_inspeccion.pdf');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error PDF: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generar PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _dato(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: ${value ?? '—'}'),
    );
  }

  int _getPassingScore(String? tipo) {
    switch (tipo) {
      case 'comercio_pequeno':
        return 70;
      case 'comercio_grande':
        return 80;
      case 'estacion_servicio':
        return 85;
      case 'industria':
        return 90;
      default:
        return 0;
    }
  }
}

