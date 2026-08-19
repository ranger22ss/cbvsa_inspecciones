import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/branding/app_branding.dart';
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
  final _nameCtrl = TextEditingController(
    text: AppBranding.inspectorDefaultName,
  );
  final _idCtrl = TextEditingController();
  final _rankCtrl = TextEditingController(text: 'Bombero');

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _rankCtrl.dispose();
    super.dispose();
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final supabase = ref.read(supabaseProvider);

    try {
      if (_isLogin) {
        final response = await supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (response.session == null) {
          throw const AuthException('No fue posible iniciar sesión.');
        }
      } else {
        final response = await supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        if (response.user == null) {
          _show('Cuenta creada. Revisa tu correo para confirmar.');
          return;
        }
        if (supabase.auth.currentUser != null) {
          await supabase
              .from('profiles')
              .update({
                'full_name': _nameCtrl.text.trim(),
                'national_id': _idCtrl.text.trim(),
                'rank': _rankCtrl.text.trim(),
              })
              .eq('id', response.user!.id);
        }
      }

      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/home');
    } on AuthException catch (error) {
      _show(error.message);
    } catch (_) {
      _show('Ocurrió un error. Comprueba la conexión e inténtalo nuevamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 28 : 18,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: wide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildBrandPanel()),
                                Expanded(child: _buildFormPanel(wide: true)),
                              ],
                            ),
                          )
                        : _buildFormPanel(wide: false),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      padding: const EdgeInsets.all(42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B2942), Color(0xFF17496E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(AppBranding.logoAssetPath!),
          ),
          const SizedBox(height: 26),
          const Text(
            'CBVSA\nInspecciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestión segura y organizada de las inspecciones institucionales.',
            style: TextStyle(
              color: Color(0xFFD7E2EA),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel({required bool wide}) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(wide ? 38 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wide) ...[
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(AppBranding.logoAssetPath!),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              _isLogin ? 'Bienvenido' : 'Crear cuenta',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              _isLogin
                  ? 'Ingresa con tu cuenta institucional.'
                  : 'Registra los datos básicos del inspector.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Ingresa un correo válido'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Mínimo 6 caracteres'
                  : null,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _idCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _rankCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rango',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                validator: _requiredValidator,
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isLogin ? Icons.login : Icons.person_add_alt_1),
              label: Text(_isLogin ? 'Ingresar' : 'Crear cuenta'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? '¿No tienes cuenta? Crear una'
                    : 'Ya tengo cuenta · Iniciar sesión',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo requerido' : null;
  }
}

