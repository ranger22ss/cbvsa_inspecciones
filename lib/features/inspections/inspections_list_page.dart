import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/templates.dart';
import 'inspection_detail_page.dart';
import 'new_inspection_wizard.dart';

final teamInspectionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabase = ref.watch(supabaseProvider);
  if (supabase.auth.currentUser == null) return [];
  final rows = await supabase
      .from('inspections')
      .select()
      .order('updated_at', ascending: false);
  return (rows as List).map((row) => Map<String, dynamic>.from(row)).toList();
});

class InspectionsListPage extends ConsumerStatefulWidget {
  const InspectionsListPage({super.key});
  @override
  ConsumerState<InspectionsListPage> createState() =>
      _InspectionsListPageState();
}

class _InspectionsListPageState extends ConsumerState<InspectionsListPage> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;

  Future<void> _open(Map<String, dynamic> row) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => InspectionDetailPage(inspection: row)),
    );
    if (updated == true) ref.invalidate(teamInspectionsProvider);
  }

  Widget _card(Map<String, dynamic> row) {
    final scheme = Theme.of(context).colorScheme;
    final result = Map<String, dynamic>.from(row['resultado'] ?? {});
    final template = templateByCode('${row['tipo_inspeccion'] ?? ''}');
    final score = _toInt(result['puntaje_total']);
    final maxScore = _toInt(result['puntaje_maximo'] ?? template.maxScore);
    final approved =
        result['aprobado'] == true ||
        score >= _toInt(result['puntaje_minimo'] ?? template.passingScore);
    final inspector = Map<String, dynamic>.from(row['inspector'] ?? {});
    final editor = Map<String, dynamic>.from(row['last_editor'] ?? {});
    final parsed = DateTime.tryParse('${row['fecha_inspeccion'] ?? ''}');
    final date = parsed == null
        ? '${row['fecha_inspeccion'] ?? '—'}'
        : DateFormat('dd/MM/yyyy').format(parsed.toLocal());
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(row),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: approved
                          ? const Color(0xFFE7F5EC)
                          : scheme.errorContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      approved ? 'APROBADO' : 'NO APROBADO',
                      style: TextStyle(
                        color: approved
                            ? const Color(0xFF176A3A)
                            : scheme.onErrorContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$score / $maxScore pts',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '${row['nombre_comercial'] ?? 'Sin nombre'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                'Radicado ${row['radicado'] ?? '—'} · ${template.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
              const Spacer(),
              const Divider(),
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      size: 17,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${inspector['nombre'] ?? 'Inspector no registrado'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          editor.isNotEmpty
                              ? 'Última edición: ${editor['nombre'] ?? 'equipo'}'
                              : 'Inspección: $date',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncRows = ref.watch(teamInspectionsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspecciones del equipo'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(teamInspectionsProvider),
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No fue posible cargar las inspecciones.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (allRows) {
          final rows = allRows.where((row) {
            final inspector = Map<String, dynamic>.from(row['inspector'] ?? {});
            final text =
                '${row['nombre_comercial']} ${row['radicado']} ${inspector['nombre']}'
                    .toLowerCase();
            return text.contains(_query.toLowerCase());
          }).toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 30 : 16,
                      20,
                      wide ? 30 : 16,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registro institucional',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${allRows.length} informes disponibles para el equipo',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por comercio, radicado o inspector',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _search.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Text('No se encontraron inspecciones.'),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              wide ? 30 : 16,
                              8,
                              wide ? 30 : 16,
                              96,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: wide ? 2 : 1,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: wide ? 1.85 : 1.75,
                                ),
                            itemCount: rows.length,
                            itemBuilder: (_, index) => _card(rows[index]),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NewInspectionWizard()),
          );
          if (created == true) ref.invalidate(teamInspectionsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva inspección'),
      ),
    );
  }
}

