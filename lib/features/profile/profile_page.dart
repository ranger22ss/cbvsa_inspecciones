import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/models.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _rankCtrl = TextEditingController();

  ProviderSubscription<AsyncValue<AppUser?>>? _userSubscription;

  @override
void initState() {
  super.initState();
  _applyUser(ref.read(currentUserProvider).valueOrNull);

  _userSubscription = ref.listenManual<AsyncValue<AppUser?>>(
    currentUserProvider,
    (previous, next) {
      next.whenData(_applyUser);
    },
  );
}

  void _applyUser(AppUser? user) {
    if (!mounted || user == null) return;
    _nameCtrl.text = user.fullName;
    _idCtrl.text = user.nationalId;
    _rankCtrl.text = user.rank;
  }

  @override
  void dispose() {
    _userSubscription?.close();
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
    try {
      await supabase.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'national_id': _idCtrl.text.trim(),
        'rank': _rankCtrl.text.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', authUser.id);

      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar perfil: $e')),
        );
      }
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
