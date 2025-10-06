import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        if (user == null) {
          Future.microtask(() => context.go('/login'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inicio'),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text('Hola, ${user.fullName}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                AppNavButton(
                  icon: Icons.person,
                  label: 'Perfil del inspector',
                  onPressed: () => context.push('/profile'),
                ),
                AppNavButton(
                  icon: Icons.assignment_add,
                  label: 'Nueva inspección',
                  // 👉 ahora abre Hoja 1 (formulario inicial)
                  onPressed: () => context.push('/inspections/start'),
                ),
                AppNavButton(
                  icon: Icons.list_alt,
                  label: 'Mis inspecciones',
                  onPressed: () => context.push('/inspections'),
                ),
                AppNavButton(
                  icon: Icons.info_outline,
                  label: 'Acerca de CBVSA',
                  onPressed: () => context.push('/about'),
                ),
                if (user.role == UserRole.admin)
                  AppNavButton(
                    icon: Icons.admin_panel_settings,
                    label: 'Panel de administración (plantillas)',
                    onPressed: () => context.push('/admin'),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error al cargar usuario'))),
    );
  }
}


