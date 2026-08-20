import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/templates.dart';
import 'inspection_detail_page.dart';
import 'new_inspection_wizard.dart';

final myInspectionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  final rows = await supabase
      .from('inspections')
      .select(
        'id, inspector_id, nombre_comercial, radicado, tipo_inspeccion, '
        'resultado, fecha_inspeccion, created_at, foto_fachada_url',
      )
      .order('created_at', ascending: false);
  return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

class InspectionsListPage extends ConsumerWidget {
  const InspectionsListPage({super.key});

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  bool _isApproved(Map<String, dynamic> row) {
    try {
      final templateCode = (row['tipo_inspeccion'] ?? '').toString();
      final template = templateByCode(templateCode);
      final resultado = row['resultado'] as Map<String, dynamic>?;
      final score = _toInt(resultado?['puntaje_total']);
      final passing = _toInt(resultado?['puntaje_minimo'] ?? template.passingScore);
      return score >= passing;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myInspectionsProvider);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inspecciones realizadas')),
      body: asyncList.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Todavía no hay inspecciones registradas.'));
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = rows[i];
              final name = r['nombre_comercial'] ?? '—';
              final radicado = r['radicado'] ?? '—';
              final templateCode = (r['tipo_inspeccion'] ?? '').toString();
              final template = templateByCode(templateCode);
              final score = _toInt(r['resultado']?['puntaje_total']);
              final maxScore = _toInt(
                r['resultado']?['puntaje_maximo'] ?? template.maxScore,
              );
              final createdAtRaw = r['created_at']?.toString();
              DateTime? createdAt;
              if (createdAtRaw != null) {
                createdAt = DateTime.tryParse(createdAtRaw)?.toLocal();
              }
              final createdText =
                  createdAt != null ? dateFormatter.format(createdAt) : '—';
              final inspectionDateRaw = (r['fecha_inspeccion'] ?? '').toString();
              DateTime? inspectionDate;
              if (inspectionDateRaw.isNotEmpty) {
                inspectionDate = DateTime.tryParse(inspectionDateRaw)?.toLocal();
              }
              final date = inspectionDate != null
                  ? dateFormatter.format(inspectionDate)
                  : inspectionDateRaw;
              final ok = _isApproved(r);
              final fotoUrl = (r['foto_fachada_url'] ?? '').toString();
              final statusColor = ok ? scheme.primary : scheme.error;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          cacheWidth: 128,
                          cacheHeight: 128,
                          filterQuality: FilterQuality.low,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: scheme.surfaceVariant,
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image, color: scheme.outline),
                          ),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.photo, color: scheme.outline),
                        ),
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Radicado: $radicado • ${template.name}'),
                    Text('Fecha inspección: $date'),
                    Text('Creada: $createdText'),
                  ],
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score / $maxScore pts',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ok ? 'APROBADO' : 'NO APROBADO',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  final inspectionId = r['id']?.toString();
                  if (inspectionId == null || inspectionId.isEmpty) return;

                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    final fullInspection = await ref
                        .read(supabaseProvider)
                        .from('inspections')
                        .select()
                        .eq('id', inspectionId)
                        .single();

                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();

                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => InspectionDetailPage(
                          inspection: Map<String, dynamic>.from(
                            fullInspection,
                          ),
                        ),
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(myInspectionsProvider);
                  }
                  } catch (error) {
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No fue posible abrir la inspección: $error',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const NewInspectionWizard(),
            ),
          );
          if (created == true) {
            ref.invalidate(myInspectionsProvider);
          }
        },
        label: const Text('Nueva'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}




