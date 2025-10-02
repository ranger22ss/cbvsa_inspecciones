import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;

  // Datos iniciales del perfil si es registro:
  final _nameCtrl = TextEditingController(text: 'Inspector CBVSA');
  final _idCtrl = TextEditingController(text: '00000000');
  final _rankCtrl = TextEditingController(text: 'Bombero');

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _rankCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final supabase = ref.read(supabaseProvider);
    try {
      if (_isLogin) {
        final res = await supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (res.session == null) {
          _showSnack('Sesión no iniciada. Revisa correo/contraseña o confirma tu email.');
          setState(() => _loading = false);
          return;
        }
      } else {
        final res = await supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        // Si tu proyecto requiere confirmación por email, puede venir null
        if (res.user == null && res.session == null) {
          _showSnack('Cuenta creada. Revisa tu correo para confirmar y luego inicia sesión.');
          setState(() => _loading = false);
          return;
        }

        // Completar perfil base (si ya hay sesión/usuario)
        final authUser = supabase.auth.currentUser ?? res.user!;
        await supabase.from('profiles').update({
          'full_name': _nameCtrl.text.trim(),
          'national_id': _idCtrl.text.trim(),
          'rank': _rankCtrl.text.trim(),
        }).eq('id', authUser.id);
      }

      // Refrescar y navegar
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/');

    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso de Inspectores')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text('CBVSA Inspecciones', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(_isLogin ? 'Modo: Iniciar sesión' : 'Modo: Crear cuenta'),
                    value: _isLogin,
                    onChanged: (v) => setState(() => _isLogin = v),
                  ),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 8),
                    Text('Datos iniciales del perfil', style: Theme.of(context).textTheme.labelLarge),
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
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: Icon(_isLogin ? Icons.login : Icons.person_add),
                    label: Text(_isLogin ? 'Ingresar' : 'Crear cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
