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
        if (user == null) {
          Future.microtask(() => context.go('/login'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final logoWidget = AppBranding.logoAssetPath != null
            ? CircleAvatar(
                radius: 42,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: AssetImage(AppBranding.logoAssetPath!),
                onBackgroundImageError: (_, __) {},
              )
            : CircleAvatar(
                radius: 42,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  AppBranding.organizationShortName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );

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
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F7FF), Color(0xFFE3ECFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          color: scheme.surface.withOpacity(0.95),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                logoWidget,
                                const SizedBox(height: 16),
                                Text(
                                  AppBranding.appName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppBranding.appTagline,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Hola, ${user.fullName}',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppNavButton(
                          icon: Icons.person,
                          label: 'Perfil del inspector',
                          onPressed: () => context.push('/profile'),
                        ),
                        const SizedBox(height: 12),
                        AppNavButton(
                          icon: Icons.assignment_add,
                          label: 'Nueva inspección',
                          onPressed: () => context.push('/inspections/start'),
                        ),
                        const SizedBox(height: 12),
                        AppNavButton(
                          icon: Icons.list_alt,
                          label: 'Mis inspecciones',
                          onPressed: () => context.push('/inspections'),
                        ),
                        const SizedBox(height: 12),
                        AppNavButton(
                          icon: Icons.info_outline,
                          label: AppBranding.aboutMenuLabel,
                          onPressed: () => context.push('/about'),
                        ),
                        if (user.role == UserRole.admin) ...[
                          const SizedBox(height: 12),
                          AppNavButton(
                            icon: Icons.admin_panel_settings,
                            label: 'Panel de administración (plantillas)',
                            onPressed: () => context.push('/admin'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error al cargar usuario'))),
    );
  }
}


