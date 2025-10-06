// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Si tienes un theme propio, mantenlo; si no, puedes borrar esta import y usar el ThemeData simple
import 'core/app_theme.dart';
import 'core/branding/app_branding.dart';

// Importa el router que te pasé (con goRouterProvider)
import 'core/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ En producción, mueve estas claves a un archivo seguro (p. ej., secrets.dart)
  await Supabase.initialize(
    url: 'https://zstebalplfztlwnezqvp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzdGViYWxwbGZ6dGx3bmV6cXZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNzQ2MzgsImV4cCI6MjA3NDc1MDYzOH0.HNHGu-dbX0MN79ykgYmoF7x-tJiD__aA0hz38SwTEQs',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: AppBranding.appName,
      // Si tienes buildAppTheme, úsalo; si no, usa el ThemeData simple.
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      // theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.red),
    );
  }
}
