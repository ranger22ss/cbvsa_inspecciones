// lib/features/inspections/inspection_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/templates.dart';
import 'new_inspection_wizard.dart';

class InspectionDetailPage extends ConsumerWidget {
  final Map<String, dynamic> inspection;
  const InspectionDetailPage({super.key, required this.inspection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = inspection;
    final modules = (inspection['modules'] ?? []) as List<dynamic>;
    final resultado = (inspection['resultado'] ?? {}) as Map<String, dynamic>;
    final puntaje = resultado['puntaje_total'] ?? inspection['score'] ?? 0;
    final aprobado = resultado['aprobado'] ?? false;
    final template = inspection['tipo_inspeccion'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de inspección'),
        actions: [
          IconButton(
            tooltip: 'Editar inspección',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NewInspectionWizard(
                  existing: inspection,
                  inspectionId: inspection['id'] as String?,
                ),
              ));
              if (context.mounted) Navigator.of(context).pop(); // recargar lista
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Radicado: ${base['radicado'] ?? '—'}'),
          Text('Fecha: ${base['fecha_inspeccion'] ?? '—'}'),
          Text('Nombre comercial: ${base['nombre_comercial'] ?? '—'}'),
          Text('Representante: ${base['representante_legal'] ?? '—'}'),
          Text('Dirección: ${base['direccion_rut'] ?? '—'}'),
          Text('Celular: ${base['celular_rut'] ?? '—'}'),
          const Divider(),
          Text('Tipo de inspección: $template'),
          Text('Puntaje: $puntaje'),
          Chip(
            label: Text(aprobado ? 'APROBADO' : 'NO APROBADO'),
            backgroundColor: aprobado ? Colors.green[100] : Colors.red[100],
          ),
          const Divider(),
          Text('Módulos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final m in modules)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['titulo'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (final q in (m['items'] ?? []) as List<dynamic>)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q['pregunta_texto'] ?? ''),
                          Text('Respuesta: ${q['respuesta'] ?? ''}'),
                          Text('Puntaje: ${q['puntaje'] ?? 0}'),
                          if ((q['fotos'] ?? []).isNotEmpty)
                            Column(
                              children: (q['fotos'] as List<dynamic>)
                                  .map((f) => ListTile(
                                        leading: f['url'] != null
                                            ? Image.network(f['url'],
                                                width: 48, height: 48, fit: BoxFit.cover)
                                            : const Icon(Icons.photo),
                                        title: Text(f['observacion'] ?? ''),
                                      ))
                                  .toList(),
                            ),
                          const Divider(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

