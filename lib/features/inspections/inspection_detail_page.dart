import 'package:flutter/material.dart';

/// Pantalla para ver una inspección guardada en modo solo lectura
class InspectionDetailPage extends StatelessWidget {
  final Map<String, dynamic> inspection;

  const InspectionDetailPage({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final nombre = (inspection['nombre_comercial'] ?? '') as String;
    final direccion = (inspection['direccion_rut'] ?? '') as String;
    final tipo = (inspection['tipo_inspeccion'] ?? '') as String;
    final radicado = (inspection['radicado'] ?? '') as String;
    final fecha = (inspection['fecha_inspeccion'] ?? '').toString();
    final fotoFachada = (inspection['foto_fachada_url'] ?? '') as String?;
    final resultado = inspection['resultado'] as Map<String, dynamic>? ?? {};
    final aprobado = resultado['aprobado'] == true;
    final puntaje = resultado['puntaje_total'] ?? inspection['score'] ?? 0;
    final modules = (inspection['modules'] ?? []) as List;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de inspección')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Radicado: $radicado', style: Theme.of(context).textTheme.titleMedium),
          Text('Fecha: $fecha'),
          Text('Tipo: $tipo'),
          Text('Nombre comercial: $nombre'),
          Text('Dirección: $direccion'),
          const SizedBox(height: 8),
          if (fotoFachada != null && fotoFachada.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Foto fachada:'),
                const SizedBox(height: 4),
                Image.network(fotoFachada, height: 150, fit: BoxFit.cover),
              ],
            ),
          const Divider(),
          Text(
            'Puntaje total: $puntaje',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Chip(
            label: Text(aprobado ? 'APROBADO' : 'NO APROBADO'),
            backgroundColor: aprobado ? Colors.green[100] : Colors.red[100],
          ),
          const SizedBox(height: 12),

          if (modules.isEmpty)
            const Text('No hay módulos registrados.')
          else
            ...modules.map((m) {
              final mod = m as Map<String, dynamic>;
              final title = mod['titulo'] ?? 'Módulo';
              final items = (mod['items'] ?? []) as List;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...items.map((item) {
                        final it = item as Map<String, dynamic>;
                        final pregunta = it['pregunta_texto'] ?? it['text'] ?? 'Pregunta';
                        final respuesta = it['respuesta'] ?? '';
                        final puntaje = it['puntaje'] ?? 0;
                        final fotos = (it['fotos'] ?? []) as List;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pregunta, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('Respuesta: $respuesta – $puntaje pts'),
                              if (fotos.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: fotos.map((f) {
                                    final ff = f as Map<String, dynamic>;
                                    final url = ff['url'] as String;
                                    final obs = ff['observacion'] ?? '';
                                    return Column(
                                      children: [
                                        Image.network(url, height: 80, width: 80, fit: BoxFit.cover),
                                        if (obs.toString().isNotEmpty)
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              obs.toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              const Divider(),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
