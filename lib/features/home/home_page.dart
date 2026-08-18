import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/branding/app_branding.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import '../../shared/widgets/app_nav_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider);
    return profile.when(
      data: (user) {
        if (user == null) { Future.microtask(() => context.go('/login')); return const Scaffold(body: Center(child: CircularProgressIndicator())); }
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Panel de inspecciones'), actions: [IconButton(tooltip: 'Cerrar sesión', onPressed: () async { await Supabase.instance.client.auth.signOut(); ref.invalidate(currentUserProvider); if (context.mounted) context.go('/login'); }, icon: const Icon(Icons.logout_rounded))]),
          body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 18, vertical: wide ? 30 : 20), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: EdgeInsets.all(wide ? 30 : 22),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B2942), Color(0xFF17496E)]), borderRadius: BorderRadius.circular(22)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(width: wide ? 86 : 68, height: wide ? 86 : 68, padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Image.asset(AppBranding.logoAssetPath!, fit: BoxFit.contain)),
                  SizedBox(width: wide ? 24 : 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CUERPO DE BOMBEROS VOLUNTARIOS', style: TextStyle(color: const Color(0xFFEDC77F), fontSize: wide ? 12 : 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)), const SizedBox(height: 7), Text('Hola, ${user.fullName.isEmpty ? 'inspector' : user.fullName}', style: TextStyle(color: Colors.white, fontSize: wide ? 28 : 21, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('${user.rank} · Gestión institucional de inspecciones', style: const TextStyle(color: Color(0xFFD7E2EA), fontSize: 13))])),
                ]),
              ),
              const SizedBox(height: 26),
              Text('Acciones principales', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6), Text('Administra el trabajo de inspección desde un solo lugar.', style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: wide ? 2 : 1, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: wide ? 2.75 : 2.6, children: [
                AppNavButton(icon: Icons.assignment_add_outlined, label: 'Nueva inspección', description: 'Iniciar un informe desde cero', onPressed: () => context.push('/inspections/start')),
                AppNavButton(icon: Icons.folder_shared_outlined, label: 'Inspecciones', description: 'Consultar y continuar informes guardados', onPressed: () => context.push('/inspections')),
                AppNavButton(icon: Icons.badge_outlined, label: 'Perfil del inspector', description: 'Datos profesionales y cuenta', onPressed: () => context.push('/profile')),
                AppNavButton(icon: Icons.info_outline_rounded, label: AppBranding.aboutMenuLabel, description: 'Información institucional', onPressed: () => context.push('/about')),
              ]),
              if (user.role == UserRole.admin) ...[const SizedBox(height: 14), AppNavButton(icon: Icons.admin_panel_settings_outlined, label: 'Administración', description: 'Plantillas y configuración institucional', onPressed: () => context.push('/admin'))],
            ]))));
          })),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No fue posible cargar el perfil.\n$error', textAlign: TextAlign.center)))),
    );
  }
}

