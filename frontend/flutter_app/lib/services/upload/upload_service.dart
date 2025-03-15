import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_service.dart';

class UploadService {
  // Singleton pattern
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  // Supabase bucket name
  final String bucketName = 'videos';

  // Reference the existing SupabaseService
  final _supabaseService = SupabaseService();

  // Upload queue
  final List<Map<String, dynamic>> _uploadQueue = [];
  bool _isUploading = false;

  // Stream controller for status updates
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // For tracking pending uploads across app restarts
  Future<void> savePendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingUploads = _uploadQueue
        .map((upload) => jsonEncode(upload))
        .toList();
    await prefs.setStringList('pending_uploads', pendingUploads);
  }

  Future<void> loadPendingUploads() async {
    if (!_supabaseService.isInitialized) {
      debugPrint('Warning: Trying to load pending uploads but Supabase is not initialized');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String>? pendingUploads = prefs.getStringList('pending_uploads');

    if (pendingUploads != null && pendingUploads.isNotEmpty) {
      _uploadQueue.addAll(
          pendingUploads.map((upload) => jsonDecode(upload) as Map<String, dynamic>)
      );

      // Start processing queue if there are pending uploads
      _processQueue();
    }
  }

  // Check network connectivity
  Future<bool> _hasNetworkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Upload a video (called after recording stops)
  Future<void> uploadVideo({
    required File videoFile,
    required Map<String, dynamic> metadata,
  }) async {
    if (!_supabaseService.isInitialized) {
      debugPrint('Error: Supabase is not initialized');
      _updateStatus(null, 'error', 'Supabase not initialized');
      return;
    }

    // Create a unique upload ID and file path
    final userId = _supabaseService.currentUserId ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'user_${userId}/presentation_$timestamp.mp4';
    final metadataFileName = 'user_${userId}/presentation_${timestamp}_metadata.json';
    final uploadId = 'upload_$timestamp';

    // Add to queue
    _uploadQueue.add({
      'id': uploadId,
      'videoPath': videoFile.path,
      'fileName': fileName,
      'metadataFileName': metadataFileName,
      'metadata': metadata,
      'attempts': 0,
      'status': 'pending',
      'progress': 0.0,
    });

    await savePendingUploads();

    // Update status
    _updateStatus(uploadId, 'queued', 'Added to upload queue');

    // Start upload if not already uploading
    if (!_isUploading) {
      _processQueue();
    }
  }

  // Update the status of an upload
  void _updateStatus(String? uploadId, String status, String message, [double progress = 0.0]) {
    _statusController.add({
      'id': uploadId,
      'status': status,
      'message': message,
      'progress': progress,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Process the upload queue
  Future<void> _processQueue() async {
    if (_uploadQueue.isEmpty || _isUploading) return;

    _isUploading = true;
    _updateStatus(null, 'processing', 'Processing upload queue');

    while (_uploadQueue.isNotEmpty) {
      var upload = _uploadQueue[0];
      final uploadId = upload['id'] as String;

      // Check if we have connection
      if (!await _hasNetworkConnection()) {
        _updateStatus(uploadId, 'waiting', 'Waiting for network connection...');
        await Future.delayed(const Duration(seconds: 10));
        continue;
      }

      // Check if Supabase session is valid
      if (_supabaseService.isSignedIn && !await _supabaseService.hasValidSession()) {
        _updateStatus(uploadId, 'error', 'Session expired. Please sign in again.');
        _isUploading = false;
        return;
      }

      try {
        // Attempt the upload
        upload['attempts'] = (upload['attempts'] ?? 0) + 1;
        _updateStatus(
            uploadId,
            'uploading',
            'Upload attempt ${upload['attempts']}...',
            0.1
        );

        final videoFile = File(upload['videoPath']);
        if (!await videoFile.exists()) {
          throw Exception('Video file not found');
        }

        final fileName = upload['fileName'];
        final metadataFileName = upload['metadataFileName'];
        final metadata = upload['metadata'];

        // Execute the upload
        await _executeSupabaseUpload(
          uploadId,
          videoFile,
          fileName,
          metadataFileName,
          metadata,
        );

        // Upload succeeded
        _uploadQueue.removeAt(0);
        _updateStatus(uploadId, 'complete', 'Upload complete!', 1.0);

        // Save updated queue
        await savePendingUploads();

      } catch (e) {
        debugPrint('Upload error: $e');

        // Handle upload failure
        if (upload['attempts'] >= 3) {
          // Max retries reached, move to next upload
          _updateStatus(uploadId, 'failed', 'Upload failed after 3 attempts');
          _uploadQueue.removeAt(0);
        } else {
          // Retry after delay
          _updateStatus(uploadId, 'retrying', 'Upload failed. Retrying in 10 seconds...');
          await Future.delayed(const Duration(seconds: 10));
        }

        // Save updated queue
        await savePendingUploads();
      }
    }

    _isUploading = false;
    _updateStatus(null, 'idle', 'Upload queue processed');
  }

  // Execute a single upload to Supabase bucket
  Future<void> _executeSupabaseUpload(
      String uploadId,
      File videoFile,
      String fileName,
      String metadataFileName,
      Map<String, dynamic> metadata,
      ) async {
    try {
      _updateStatus(uploadId, 'uploading', 'Uploading video...', 0.2);

      // Upload video file to Supabase bucket
      await _supabaseService.client
          .storage
          .from(bucketName)
          .upload(
        fileName,
        videoFile,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      _updateStatus(uploadId, 'uploading', 'Video uploaded. Processing metadata...', 0.8);

      // Upload metadata as JSON file
      final metadataJson = jsonEncode(metadata);
      final metadataBytes = utf8.encode(metadataJson);

      await _supabaseService.client
          .storage
          .from(bucketName)
          .uploadBinary(
        metadataFileName,
        metadataBytes,
        fileOptions: FileOptions(
          contentType: 'application/json',
          upsert: true,
        ),
      );

      _updateStatus(uploadId, 'processing', 'Creating database record...', 0.9);

      // Get the public URL of the video
      final videoUrl = _supabaseService.client
          .storage
          .from(bucketName)
          .getPublicUrl(fileName);

      // Create a database record for the upload
      // await _supabaseService.client
      //     .from('presentation_recordings')
      //     .insert({
      //   'video_url': videoUrl,
      //   'metadata_file': metadataFileName,
      //   'created_at': DateTime.now().toIso8601String(),
      //   'status': 'uploaded',
      //   'user_id': _supabaseService.currentUserId,
      // });

      _updateStatus(uploadId, 'complete', 'Upload and processing complete', 1.0);

    } catch (e) {
      debugPrint('Supabase upload error: $e');
      throw Exception('Failed to upload to Supabase: $e');
    }
  }

  // Call this when the app is shutting down
  void dispose() {
    _statusController.close();
  }
}