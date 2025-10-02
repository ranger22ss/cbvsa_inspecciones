import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _rankCtrl;

  @override
  void initState() {
    super.initState();
    final asyncUser = ref.read(currentUserProvider);
    asyncUser.whenData((user) {
      if (mounted && user != null) {
        _nameCtrl = TextEditingController(text: user.fullName);
        _idCtrl = TextEditingController(text: user.nationalId);
        _rankCtrl = TextEditingController(text: user.rank);
        setState(() {});
      }
    });
    // Valores por defecto mientras carga
    _nameCtrl = TextEditingController(text: '');
    _idCtrl = TextEditingController(text: '');
    _rankCtrl = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _rankCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final supabase = ref.read(supabaseProvider);
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return;

    await supabase.from('profiles').update({
      'full_name': _nameCtrl.text.trim(),
      'national_id': _idCtrl.text.trim(),
      'rank': _rankCtrl.text.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', authUser.id);

    // refrescar provider
    ref.invalidate(currentUserProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);

    return profile.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Sin sesión')));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Perfil del inspector')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  CircleAvatar(radius: 36, child: Text(user.fullName.isNotEmpty ? user.fullName[0] : '?')),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(labelText: 'Cédula'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _rankCtrl,
                    decoration: const InputDecoration(labelText: 'Rango'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error al cargar perfil'))),
    );
  }
}
