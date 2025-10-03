import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Páginas de tu app
import '../features/auth/login_page.dart';
import '../features/home/home_page.dart';
import '../features/profile/profile_page.dart';
import '../features/inspections/inspections_list_page.dart';
import '../features/inspections/new_inspection_wizard.dart';

// --- Utilidad para refrescar GoRouter cuando cambia el auth ---
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// --- Provider del router (Riverpod) ---
final goRouterProvider = Provider<GoRouter>((ref) {
  final supabase = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
      supabase.auth.onAuthStateChange, // refresca al login/logout
    ),
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/inspections',
        builder: (context, state) => const InspectionsListPage(),
      ),
      // Nueva inspección: siempre inicia en Hoja 1 del wizard
      GoRoute(
        path: '/inspections/start',
        builder: (context, state) => const NewInspectionWizard(),
      ),
      // (opcional) Crear directo con wizard vacío
      GoRoute(
        path: '/inspections/new',
        builder: (context, state) => const NewInspectionWizard(),
      ),
      // (opcional) Editar por id via extra
      GoRoute(
        path: '/inspections/:id/edit',
        builder: (context, state) {
          final extra = state.extra;
          Map<String, dynamic>? existing;
          if (extra is Map<String, dynamic> && extra['existing'] is Map) {
            existing = Map<String, dynamic>.from(
                extra['existing'] as Map<dynamic, dynamic>);
          }
          return NewInspectionWizard(
            existing: existing,
            inspectionId: state.pathParameters['id'],
          );
        },
      ),
    ],
  );
});


