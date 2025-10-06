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
import '../features/inspections/summary_conclusion_page.dart';

class Routes {
  const Routes._();

  static const String login = 'login';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String inspections = 'inspections';
  static const String inspectionsStart = 'inspections_start';
  static const String inspectionsNew = 'inspections_new';
  static const String inspectionsEdit = 'inspections_edit';

  // ignore: constant_identifier_names
  static const String pagina_aval_anual = 'pagina_aval_anual';
}

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
        name: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        name: Routes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/inspections',
        name: Routes.inspections,
        builder: (context, state) => const InspectionsListPage(),
      ),
      // Nueva inspección: siempre inicia en Hoja 1 del wizard
      GoRoute(
        path: '/inspections/start',
        name: Routes.inspectionsStart,
        builder: (context, state) => const NewInspectionWizard(),
      ),
      // (opcional) Crear directo con wizard vacío
      GoRoute(
        path: '/inspections/new',
        name: Routes.inspectionsNew,
        builder: (context, state) => const NewInspectionWizard(),
      ),
      // (opcional) Editar por id via extra
      GoRoute(
        path: '/inspections/:id/edit',
        name: Routes.inspectionsEdit,
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
      GoRoute(
        path: '/inspections/summary',
        name: Routes.pagina_aval_anual,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SummaryConclusionArgs) {
            return const Scaffold(
              body: Center(
                child: Text('Datos de inspección no disponibles'),
              ),
            );
          }
          return SummaryConclusionPage(data: extra);
        },
      ),
    ],
  );
});


