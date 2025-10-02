import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import '../../core/templates.dart';            // 👈 IMPORTA PLANTILLAS
import 'new_inspection_wizard.dart';

final myInspectionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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

  bool _isApproved(Map<String, dynamic> row) {
    try {
      final template = (row['tipo_inspeccion'] ?? '').toString();
      final score = (row['score'] ?? 0) as int;
      final t = templates.firstWhere((e) => e.code == template);
      return score >= t.passingScore;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myInspectionsProvider);

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
              final score = r['score'] ?? 0;
              final template = r['tipo_inspeccion'] ?? '';
              final date = (r['inspection_date'] ?? '').toString();
              final ok = _isApproved(r);

              return ListTile(
                title: Text(name),
                subtitle: Text('$template • $date'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$score pts'),
                    Text(ok ? 'APROBADO' : 'NO APROBADO',
                        style: TextStyle(
                          color: ok ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => NewInspectionWizard(
                      existing: r,
                      inspectionId: r['id'] as String,
                    ),
                  ));
                  // refrescar al volver
                  // ignore: use_build_context_synchronously
                  ref.invalidate(myInspectionsProvider);
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
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const NewInspectionWizard(),
          ));
          // refrescar al volver
          // ignore: use_build_context_synchronously
          ref.invalidate(myInspectionsProvider);
        },
        label: const Text('Nueva'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

