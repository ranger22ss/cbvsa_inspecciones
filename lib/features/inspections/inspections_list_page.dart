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
      .select()
      .eq('inspector_id', user.id)
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

  Future<void> _deleteInspection(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> inspection,
  ) async {
    final id = inspection['id'];
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar inspección'),
          content: const Text(
            '¿Desea eliminar esta inspección? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final supabase = ref.read(supabaseProvider);
    try {
      await supabase.from('inspections').delete().eq('id', id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: const Text('Inspección eliminada'),
          ),
        );
      }
      ref.invalidate(myInspectionsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('No se pudo eliminar: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myInspectionsProvider);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis inspecciones')),
      body: asyncList.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Todavía no hay inspecciones.'));
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
                trailing: SizedBox(
                  width: 132,
                  child: Column(
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar inspección',
                            icon: Icon(Icons.edit, color: scheme.primary),
                            onPressed: () async {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => NewInspectionWizard(
                                    existing: Map<String, dynamic>.from(r),
                                    inspectionId: r['id']?.toString(),
                                  ),
                                ),
                              );
                              if (result == true && context.mounted) {
                                ref.invalidate(myInspectionsProvider);
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: Icon(Icons.delete_outline, color: scheme.error),
                            onPressed: () => _deleteInspection(context, ref, r),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          InspectionDetailPage(inspection: r),
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(myInspectionsProvider);
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



