import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
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

  // Reference to the chunking service
  //final _chunkingService = VideoChunkingService();

  // Upload queue
  final List<Map<String, dynamic>> _uploadQueue = [];
  bool _isUploading = false;

  // Stream controller for status updates
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  // Map to track processing status of reports and their processing start times
  final Map<String, DateTime> _processingStartTimes = {};

  // Map to track API call success status
  final Map<String, bool> _apiCallSuccess = {};

  // For tracking pending uploads across app restarts
  Future<void> savePendingUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingUploads =
        _uploadQueue.map((upload) => jsonEncode(upload)).toList();
    await prefs.setStringList('pending_uploads', pendingUploads);
  }

  Future<void> loadPendingUploads() async {
    if (!_supabaseService.isInitialized) {
      debugPrint(
          'Warning: Trying to load pending uploads but Supabase is not initialized');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String>? pendingUploads = prefs.getStringList('pending_uploads');

    if (pendingUploads != null && pendingUploads.isNotEmpty) {
      _uploadQueue.addAll(pendingUploads
          .map((upload) => jsonDecode(upload) as Map<String, dynamic>));

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
    required String reportId,
  }) async {
    if (!_supabaseService.isInitialized) {
      debugPrint('Error: Supabase is not initialized');
      _updateStatus(null, 'error', 'Supabase not initialized');
      return;
    }

    // Create a unique upload ID and file path
    final userId = _supabaseService.currentUserId ?? 'anonymous';
    final folderPath = 'user_${userId}/presentation_${reportId}';
    final fileName = '$folderPath/video_${reportId}.mp4';
    final metadataFileName = '$folderPath/metadata.json';
    final uploadId = 'upload_$reportId';

    // Check if the file needs chunking
    //final needsChunking = await _chunkingService.needsChunking(videoFile);

    // Add to queue with chunking information
    _uploadQueue.add({
      'id': uploadId,
      'videoPath': videoFile.path,
      'fileName': fileName,
      'metadataFileName': metadataFileName,
      'metadata': metadata,
      'attempts': 0,
      'status': 'pending',
      'progress': 0.0,
      //'needsChunking': needsChunking,
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
  void _updateStatus(String? uploadId, String status, String message,
      [double progress = 0.0]) {
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
      if (_supabaseService.isSignedIn &&
          !await _supabaseService.hasValidSession()) {
        _updateStatus(
            uploadId, 'error', 'Session expired. Please sign in again.');
        _isUploading = false;
        return;
      }

      try {
        // Attempt the upload
        upload['attempts'] = (upload['attempts'] ?? 0) + 1;
        _updateStatus(uploadId, 'uploading',
            'Upload attempt ${upload['attempts']}...', 0.1);

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
          _updateStatus(
              uploadId, 'retrying', 'Upload failed. Retrying in 10 seconds...');
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
      _updateStatus(uploadId, 'uploading', 'Preparing video...', 0.1);

      // Determine if chunking is needed
      // bool needsChunking = await _chunkingService.needsChunking(videoFile);

      // if (needsChunking) {
      //   // Handle chunked upload
      //   await _uploadInChunks(uploadId, videoFile, fileName, metadataFileName, metadata);
      // } else {
      // Normal single file upload
      _updateStatus(uploadId, 'uploading', 'Uploading video...', 0.2);

      // Upload video file to Supabase bucket
      await _supabaseService.client.storage.from(bucketName).upload(
            fileName,
            videoFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      _updateStatus(
          uploadId, 'uploading', 'Video uploaded. Processing metadata...', 0.8);

      // Upload metadata as JSON file
      final metadataJson = jsonEncode(metadata);
      final metadataBytes = utf8.encode(metadataJson);

      await _supabaseService.client.storage.from(bucketName).uploadBinary(
            metadataFileName,
            metadataBytes,
            fileOptions: FileOptions(
              contentType: 'application/json',
              upsert: true,
            ),
          );
      //}

      _updateStatus(uploadId, 'processing', 'Creating database record...', 0.9);

      // Get the public URL of the video (or first chunk if chunked)
      final videoUrl = await _supabaseService.client.storage
          .from(bucketName)
          .createSignedUrl(fileName, 604800);
      // debugPrint(videoUrl);
      final reportId = metadata['reportId'];

      if (reportId != null) {
        try {
          debugPrint('Checking if reportId $reportId exists in UserReport...');

          // First check if the record with this reportId exists
          final checkResponse = await Supabase.instance.client
              .from('UserReport')
              .select('reportId')
              .eq('reportId', reportId)
              .single();

          if (checkResponse != null) {
            debugPrint(
                'Found reportId $reportId in UserReport, proceeding with update');

            // Get the signed URL of the video
            final videoUrl = await _supabaseService.client.storage
                .from(bucketName)
                .createSignedUrl(fileName, 604800);
            debugPrint('Generated video URL: $videoUrl');
            debugPrint('Report ID: $reportId');

            // Perform the update
            final response = await Supabase.instance.client
                .from('UserReport')
                .update({'videoUrl': videoUrl.toString()})
                .eq('reportId', reportId)
                .select();

            if (response != null && response.isNotEmpty) {
              debugPrint('Successfully updated UserReport video URL.');
              debugPrint('Updated records: ${response.length}');
              // await callPythonVideoController(videoUrl, reportId); //calling the python video controller
            } else {
              debugPrint(
                  'Update query executed but no records were updated in UserReport.');
            }
          } else {
            debugPrint(
                'Error: No record found with reportId $reportId in UserReport');
          }
        } catch (e) {
          debugPrint('Exception checking/updating UserReport: $e');
        }
      } else {
        debugPrint(
            'Warning: No reportId provided in metadata, could not update UserReport');
      }

      // After successful upload, trigger the backend analysis
      try {
        // Get reportId from metadata
        final reportId = metadata['reportId'];
        if (reportId == null) {
          debugPrint(
              'Warning: No reportId found in metadata, skipping backend call');
          return;
        }

        debugPrint('Attempting to call backend API for report: $reportId');
        debugPrint('Video URL: $videoUrl');

        // Create HTTP client that follows redirects
        final client = http.Client();

        try {
          // Use the correct endpoint with trailing slash
          final apiUrl = Uri.parse('http://10.0.2.2:8000/api/process/');

          // Add parameters as query parameters, not in body
          final urlWithParams = apiUrl.replace(queryParameters: {
            'video_url': videoUrl,
            'report_id': reportId,
          });

          debugPrint('Calling API with URL: ${urlWithParams.toString()}');

          final response = await client
              .post(urlWithParams)
              .timeout(const Duration(seconds: 30));

          _apiCallSuccess[reportId] = response.statusCode == 200;
          _processingStartTimes[reportId] = DateTime.now();

          debugPrint('Backend API response status: ${response.statusCode}');
          debugPrint('Backend API response body: ${response.body}');

          if (response.statusCode == 200) {
            _updateStatus(
                uploadId, 'analyzing', 'Video analysis started...', 0.95);
            debugPrint('Analysis successfully started for report $reportId');
          } else {
            debugPrint(
                'Failed to trigger analysis: ${response.statusCode} - ${response.body}');
            _updateStatus(uploadId, 'warning',
                'Upload complete but analysis may be delayed', 0.95);
          }
        } catch (e) {
          debugPrint("Error calling API: $e");
          _apiCallSuccess[reportId] = false;
          _processingStartTimes[reportId] = DateTime.now();
          _updateStatus(uploadId, 'warning',
              'Upload complete but analysis may be delayed', 0.95);
        } finally {
          client.close();
        }
      } catch (e) {
        debugPrint("Error in backend processing: $e");
        if (metadata['reportId'] != null) {
          _apiCallSuccess[metadata['reportId']] = false;
          _processingStartTimes[metadata['reportId']] = DateTime.now();
        }
        _updateStatus(uploadId, 'warning',
            'Upload complete but analysis may be delayed', 0.95);
      }

      // Clean up the original local video file after successful upload
      try {
        // Delete directory instead of just the file (similar to camera_function.dart)
        if (await videoFile.exists()) {
          final directory = videoFile.parent;
          if (await directory.exists()) {
            await directory.delete(recursive: true);
            debugPrint(
                'Original video directory deleted after successful upload: ${directory.path}');
          } else {
            // If directory doesn't exist, try to delete just the file
            await videoFile.delete();
            debugPrint(
                'Original video file deleted after successful upload: ${videoFile.path}');
          }
        }
      } catch (e) {
        // Don't fail the upload if cleanup fails
        debugPrint('Warning: Could not delete original video file: $e');
      }

      _updateStatus(uploadId, 'complete', 'Upload complete!', 1.0);
    } catch (e) {
      debugPrint('Supabase upload error: $e');
      throw Exception('Failed to upload to Supabase: $e');
    }
  }

  // Add this method to check processing status
  Future<bool> checkProcessingStatus(String reportId) async {
    try {
      debugPrint('Checking processing status for report: $reportId');

      // Get the API call success status
      final apiSuccess = _apiCallSuccess[reportId] ?? false;
      debugPrint('API call success: $apiSuccess');

      // Get when processing started
      final startTime = _processingStartTimes[reportId];
      if (startTime == null) {
        debugPrint('No processing start time recorded');
        return false;
      }

      final elapsed = DateTime.now().difference(startTime);
      debugPrint(
          'Time elapsed since processing started: ${elapsed.inSeconds} seconds');

      // Simple time-based approach with different times based on API status
      if (apiSuccess) {
        // Successful API call - minimum wait time for UX
        return elapsed.inSeconds >= 5;
      } else {
        // Failed API call - show error after shorter wait
        return elapsed.inSeconds >= 3;
      }
    } catch (e) {
      debugPrint('Error checking processing status: $e');

      // Fallback - consider complete after brief delay
      final startTime = _processingStartTimes[reportId];
      if (startTime != null) {
        return DateTime.now().difference(startTime).inSeconds > 8;
      }
      return false;
    }
  }

  // Call this when the app is shutting down
  void dispose() {
    _statusController.close();
  }
}
