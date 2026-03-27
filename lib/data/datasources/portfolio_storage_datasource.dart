import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_image_compress/fast_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase/supabase.dart';

import '../../core/config/supabase_config.dart';

/// Uploads portfolio media (images/videos) and profile photos via direct Supabase Storage.
/// Uses get-upload-url Edge Function to obtain a signed upload token, then uploads
/// directly to Storage (single hop) for faster uploads and fewer timeouts.
class PortfolioStorageDataSource {
  PortfolioStorageDataSource({
    String? getUploadUrlUrl,
    SupabaseClient? supabaseClient,
  })  : _getUploadUrlUrl =
            getUploadUrlUrl ??
            '${SupabaseConfig.url}/functions/v1/get-upload-url',
        _supabase = supabaseClient ??
            SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);

  static const Duration _uploadTimeout = Duration(seconds: 90);

  final String _getUploadUrlUrl;
  final SupabaseClient _supabase;
  final FastImageCompress _imageCompress = FastImageCompress();

  /// Requests a signed upload URL from the Edge Function (auth only, no file).
  Future<({String path, String token, String publicUrl})> _getSignedUploadUrl({
    required String firebaseToken,
    required String type,
    required String fileName,
    bool isVideo = false,
  }) async {
    final body = type == 'profile'
        ? <String, dynamic>{'type': 'profile', 'fileName': fileName}
        : <String, dynamic>{
            'type': 'portfolio',
            'isVideo': isVideo,
            'fileName': fileName,
          };
    final response = await http.post(
      Uri.parse(_getUploadUrlUrl),
      headers: {
        'Authorization': 'Bearer $firebaseToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      String message = 'Upload failed: ${response.statusCode}';
      if (response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final err = json['error'] as String?;
          if (err != null && err.isNotEmpty) message = err;
        } catch (_) {
          message = response.body.length > 200
              ? '${response.body.substring(0, 200)}...'
              : response.body;
        }
      }
      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final path = data['path'] as String?;
    final token = data['token'] as String?;
    final publicUrl = data['publicUrl'] as String?;
    if (path == null || path.isEmpty || token == null || token.isEmpty) {
      throw Exception('Invalid response from upload service');
    }
    if (publicUrl == null || publicUrl.isEmpty) {
      throw Exception('No public URL in response');
    }
    return (path: path, token: token, publicUrl: publicUrl);
  }

  /// Uploads a file and returns its public download URL.
  Future<String> uploadPortfolioMedia(
    XFile file,
    String userId, {
    required bool isVideo,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final fileName = file.name.isNotEmpty ? file.name : 'upload';
    final signed = await _getSignedUploadUrl(
      firebaseToken: token,
      type: 'portfolio',
      fileName: fileName,
      isVideo: isVideo,
    );

    var bytes = await file.readAsBytes();
    if (!isVideo) {
      bytes = await _compressImage(
        bytes,
        quality: 70,
        targetWidth: 1920,
        imageQuality: ImageQuality.medium,
      );
    }
    await _supabase.storage
        .from('portfolio')
        .uploadBinaryToSignedUrl(signed.path, signed.token, bytes)
        .timeout(
          _uploadTimeout,
          onTimeout: () =>
              throw Exception('Upload timed out. Check your connection.'),
        );

    return signed.publicUrl;
  }

  /// Compresses image bytes using fast_image_compress. Returns compressed bytes.
  Future<Uint8List> _compressImage(
    Uint8List imageData, {
    required int quality,
    required int? targetWidth,
    required ImageQuality imageQuality,
  }) async {
    try {
      final result = await _imageCompress.compressImage(
        imageData: imageData,
        quality: quality,
        targetWidth: targetWidth,
        imageQuality: imageQuality,
      );
      if (result == null || result.isEmpty) {
        throw Exception(
          'Image compression failed. Please try another photo.',
        );
      }
      return result;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Image compression failed. Please try another photo.',
      );
    }
  }

  /// Uploads a profile photo and returns its public URL.
  /// Path: users/{uid}/profile/avatar.{ext} (overwrites previous).
  Future<String> uploadProfilePhoto(XFile file, String userId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Could not read image file. Please try a different photo.');
    }
    final fileName = file.name.isNotEmpty ? file.name : 'avatar.jpg';

    final uploadBytes = await _compressImage(
      bytes,
      quality: 70,
      targetWidth: 512,
      imageQuality: ImageQuality.medium,
    );

    final signed = await _getSignedUploadUrl(
      firebaseToken: token,
      type: 'profile',
      fileName: fileName,
    );

    await _supabase.storage
        .from('portfolio')
        .uploadBinaryToSignedUrl(signed.path, signed.token, uploadBytes)
        .timeout(
          _uploadTimeout,
          onTimeout: () =>
              throw Exception('Upload timed out. Check your connection.'),
        );

    return signed.publicUrl;
  }
}
