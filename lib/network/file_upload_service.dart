import 'dart:async';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:mg_common_game/network/api_client.dart';
import 'package:mg_common_game/storage/cache_strategy.dart';

/// Upload progress callback
typedef UploadProgressCallback = void Function(int bytesSent, int totalBytes);

/// Upload result
class UploadResult {
  final bool success;
  final String? url;
  final String? error;
  final String? fileId;
  final int? fileSize;

  UploadResult({
    required this.success,
    this.url,
    this.error,
    this.fileId,
    this.fileSize,
  });

  /// Create success result
  factory UploadResult.successful({
    required String url,
    String? fileId,
    int? fileSize,
  }) {
    return UploadResult(
      success: true,
      url: url,
      fileId: fileId,
      fileSize: fileSize,
    );
  }

  /// Create error result
  factory UploadResult.failure({
    required String error,
  }) {
    return UploadResult(
      success: false,
      error: error,
    );
  }
}

/// File metadata
class FileMetadata {
  final String fileName;
  final String? mimeType;
  final int fileSize;
  final DateTime? createdAt;
  final String? uploaderId;

  FileMetadata({
    required this.fileName,
    this.mimeType,
    required this.fileSize,
    this.createdAt,
    this.uploaderId,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'uploaderId': uploaderId,
    };
  }

  /// Create from JSON
  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      fileName: json['fileName'],
      mimeType: json['mimeType'],
      fileSize: json['fileSize'],
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      uploaderId: json['uploaderId'],
    );
  }
}

/// Upload options
class UploadOptions {
  final String? category;
  final bool isPublic;
  final Map<String, String>? metadata;
  final UploadProgressCallback? onProgress;
  final int? maxRetries;
  final Duration? timeout;

  const UploadOptions({
    this.category,
    this.isPublic = false,
    this.metadata,
    this.onProgress,
    this.maxRetries,
    this.timeout,
  });
}

/// File upload service
class FileUploadService {
  static final FileUploadService _instance = FileUploadService._internal();
  static FileUploadService get instance => _instance;

  FileUploadService._internal();

  final ApiClient _apiClient = ApiClient.instance;
  final CacheStrategy _cache = CacheStrategy.instance;

  final Map<String, UploadProgressCallback> _activeUploads = {};
  final StreamController<UploadResult> _uploadController = StreamController.broadcast();

  /// Stream of upload results
  Stream<UploadResult> get uploadStream => _uploadController.stream;

  /// Upload single file
  Future<UploadResult> uploadFile(
    String filePath, {
    UploadOptions? options,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return UploadResult.failure(error: 'File does not exist: $filePath');
    }

    final fileName = path.basename(filePath);
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
    final fileSize = await file.length();

    try {
      final response = await _apiClient.uploadFile<Map<String, dynamic>>(
        '/files/upload',
        filePath,
        'file',
        fields: {
          'fileName': fileName,
          'mimeType': mimeType,
          'category': options?.category ?? 'general',
          'isPublic': options?.isPublic.toString() ?? 'false',
          ...?options?.metadata,
        },
        options: ApiOptions(
          timeout: options?.timeout ?? const Duration(minutes: 5),
        ),
        dataParser: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final result = UploadResult.successful(
          url: data['url'],
          fileId: data['fileId'],
          fileSize: fileSize,
        );

        _uploadController.add(result);
        return result;
      } else {
        final result = UploadResult.failure(
          error: response.error ?? 'Upload failed',
        );
        _uploadController.add(result);
        return result;
      }
    } catch (e) {
      final result = UploadResult.failure(error: 'Upload error: $e');
      _uploadController.add(result);
      return result;
    }
  }

  /// Upload multiple files
  Future<List<UploadResult>> uploadFiles(
    List<String> filePaths, {
    UploadOptions? options,
    bool parallel = true,
  }) async {
    if (parallel) {
      // Upload all files in parallel
      final futures = filePaths.map((filePath) {
        return uploadFile(filePath, options: options);
      });

      return await Future.wait(futures);
    } else {
      // Upload files sequentially
      final results = <UploadResult>[];

      for (final filePath in filePaths) {
        final result = await uploadFile(filePath, options: options);
        results.add(result);

        // Stop on first error
        if (!result.success) {
          break;
        }
      }

      return results;
    }
  }

  /// Upload file bytes
  Future<UploadResult> uploadBytes(
    String fileName,
    List<int> bytes,
    String mimeType, {
    UploadOptions? options,
  }) async {
    // Save bytes to temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    try {
      return await uploadFile(tempFile.path, options: options);
    } finally {
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Upload image with optimization
  Future<UploadResult> uploadImage(
    String imagePath, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
    UploadOptions? options,
  }) async {
    // For now, just upload the file as-is
    // In a real implementation, you would optimize the image here
    return await uploadFile(imagePath, options: options);
  }

  /// Delete file
  Future<bool> deleteFile(String fileId) async {
    try {
      final response = await _apiClient.delete<void>(
        '/files/$fileId',
        dataParser: (_) => null,
      );

      return response.success;
    } catch (e) {
      print('Delete file error: $e');
      return false;
    }
  }

  /// Get file metadata
  Future<FileMetadata?> getFileMetadata(String fileId) async {
    try {
      // Try cache first
      final cached = _cache.get<FileMetadata>('file_metadata', fileId);
      if (cached != null) {
        return cached;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/files/$fileId',
        dataParser: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final metadata = FileMetadata.fromJson(response.data!);

        // Cache the metadata
        await _cache.put('file_metadata', fileId, metadata);

        return metadata;
      }

      return null;
    } catch (e) {
      print('Get file metadata error: $e');
      return null;
    }
  }

  /// Get download URL for file
  Future<String?> getDownloadUrl(String fileId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/files/$fileId/url',
        dataParser: (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        return response.data!['url'] as String;
      }

      return null;
    } catch (e) {
      print('Get download URL error: $e');
      return null;
    }
  }

  /// Cancel active upload
  void cancelUpload(String uploadId) {
    _activeUploads.remove(uploadId);
  }

  /// Cancel all active uploads
  void cancelAllUploads() {
    _activeUploads.clear();
  }

  /// Clear file metadata cache
  Future<void> clearCache() async {
    await _cache.clear('file_metadata');
  }

  /// Dispose of resources
  void dispose() {
    _uploadController.close();
  }

  // ==================== Utility Methods ====================

  /// Validate file type
  bool isValidFileType(String filePath, List<String> allowedTypes) {
    final mimeType = lookupMimeType(filePath);
    return mimeType != null && allowedTypes.any((type) => mimeType.startsWith(type));
  }

  /// Validate file size
  bool isValidFileSize(String filePath, int maxSizeInBytes) async {
    final file = File(filePath);
    final fileSize = await file.length();
    return fileSize <= maxSizeInBytes;
  }

  /// Get file size in human-readable format
  String formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// Generate unique file name
  String generateUniqueFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalFileName);
    final baseName = path.basenameWithoutExtension(originalFileName);
    return '${baseName}_$timestamp$extension';
  }

  /// Validate image file
  bool isValidImage(String filePath) {
    return isValidFileType(filePath, ['image/']);
  }

  /// Validate video file
  bool isValidVideo(String filePath) {
    return isValidFileType(filePath, ['video/']);
  }

  /// Validate document file
  bool isValidDocument(String filePath) {
    return isValidFileType(filePath, ['application/pdf', 'application/msword', 'application/']);
  }
}
