import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Uploads a file to a specific bucket and returns the public or signed URL.
  Future<String> uploadFile({
    required String bucketName,
    required dynamic file,
    required String pathPrefix,
    required String fileName,
  }) async {
    // Sanitize the filename to avoid spaces and unsafe characters which may
    // cause HTTP 400 responses from some storage backends.
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final normalizedFileName = '${const Uuid().v4()}_$safeName';
    final fullPath = '$pathPrefix/$normalizedFileName';
    final bytes = await _normalizeFile(file);

    // When we have raw bytes (Uint8List) prefer uploadBinary to avoid
    // SDK implementations that attempt to access a `path` property on
    // the file (which doesn't exist in browser Uint8List wrappers).
    final storageApi = _supabase.storage.from(bucketName) as dynamic;
    if (bytes is Uint8List) {
      try {
        await storageApi.uploadBinary(fullPath, bytes);
      } on NoSuchMethodError {
        await storageApi.upload(
          fullPath,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
      }
    } else {
      await storageApi.upload(
        fullPath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
    }

    // If it's the avatars bucket, it's public. Otherwise, we return a signed URL or path.
    if (bucketName == 'avatars') {
      return _supabase.storage.from(bucketName).getPublicUrl(fullPath);
    } else {
      // For private buckets, we return the path and generate signed URLs dynamically when viewing
      return fullPath;
    }
  }

  Future<dynamic> _normalizeFile(dynamic file) async {
    if (file is Uint8List) return file;
    if (file is List<int>) return Uint8List.fromList(file);
    if (file is XFile) return await file.readAsBytes();
    throw UnsupportedError('Unsupported file type: ${file.runtimeType}');
  }

  /// Gets a signed URL valid for 1 hour for private documents
  Future<String> getSignedUrl(String bucketName, String path) async {
    return await _supabase.storage.from(bucketName).createSignedUrl(path, 3600);
  }

  /// Deletes a file from storage
  Future<void> deleteFile(String bucketName, String path) async {
    await _supabase.storage.from(bucketName).remove([path]);
  }
}
