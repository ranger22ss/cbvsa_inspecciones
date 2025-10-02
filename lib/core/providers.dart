import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Cambios de sesión (login/logout)
final supabaseSessionProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(supabaseProvider).auth;
  return auth.onAuthStateChange.map((event) => event);
});

/// Perfil garantizado por RPC: crea si falta, y lo retorna
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final authUser = supabase.auth.currentUser;
  if (authUser == null) return null;

  final res = await supabase.rpc('upsert_profile', params: {});
  final data = Map<String, dynamic>.from(res as Map);
  data['id'] = authUser.id; // asegurar id para el mapper

  return AppUser.fromMap(data);
});
