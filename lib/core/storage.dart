import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;
  StorageService(this._client);

  Future<String> uploadImage({
    required File file,
    required String userId,
    required String questionId,
  }) async {
    final ext = p.extension(file.path).toLowerCase();
    final id = const Uuid().v4();

    // Ruta simple y única: <uid>/<questionId>/<uuid>.jpg
    final path = '$userId/$questionId/$id$ext';

    await _client.storage.from('inspections').upload(
      path,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
        contentType: 'image/jpeg',
      ),
    );

    // Bucket público: obtenemos URL pública directa
    return _client.storage.from('inspections').getPublicUrl(path);
  }
}
