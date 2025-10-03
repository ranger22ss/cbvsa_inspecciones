import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/templates.dart';
import 'create_inspection_intro_page.dart';  // 👉 Hoja 1
import 'inspection_detail_page.dart';       // 👉 Nuevo detalle

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

  bool _isApproved(Map<String, dynamic> row) {
    try {
      final template = (row['tipo_inspeccion'] ?? '').toString();
      final score = (row['resultado']?['puntaje_total'] ?? 0) as int;
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
              final radicado = r['radicado'] ?? '—';
              final score = (r['resultado']?['puntaje_total'] ?? 0) as int;
              final template = r['tipo_inspeccion'] ?? '';
              final date = (r['fecha_inspeccion'] ?? '').toString();
              final ok = _isApproved(r);

              return ListTile(
                title: Text(name),
                subtitle: Text('Radicado: $radicado • $template • $date'),
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
                    builder: (_) =>
                        InspectionDetailPage(inspection: r), // 👈 abre detalle
                  ));
                  // refrescar al volver
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
            builder: (_) => const CreateInspectionIntroPage(), // 👈 Hoja 1
          ));
          ref.invalidate(myInspectionsProvider);
        },
        label: const Text('Nueva'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}



