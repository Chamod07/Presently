import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class VideoChunkingService {
  // Singleton pattern
  static final VideoChunkingService _instance = VideoChunkingService._internal();
  factory VideoChunkingService() => _instance;
  VideoChunkingService._internal();

  // Maximum size for single file upload (50MB in bytes)
  final int maxFileSize = 50 * 1024 * 1024;

  // Check if file needs chunking (exceeds max file size)
  Future<bool> needsChunking(File file) async {
    final fileSize = await file.length();
    return fileSize > maxFileSize;
  }

  // Get video duration using FFmpeg
  Future<double> getVideoDuration(String videoPath) async {
    try {
      // Run FFprobe to get duration
      final command = '-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$videoPath"';
      final session = await FFmpegKit.execute(command);
      final output = await session.getOutput();

      if (output != null && output.isNotEmpty) {
        return double.parse(output.trim());
      } else {
        // Fallback if FFprobe fails
        return 10.0; // Assume 10 seconds if we can't determine duration
      }
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return 10.0; // Fallback duration
    }
  }

  // Create video chunks with FFmpeg
  Future<List<File>> createVideoChunks({
    required String uploadId,
    required File videoFile,
    required String outputDir,
    required int numChunks,
    required double chunkDuration,
    required Function(String, String, String, double) statusCallback,
  }) async {
    List<File> chunks = [];

    try {
      final filePath = videoFile.path;

      for (int i = 0; i < numChunks; i++) {
        final chunkIndex = i + 1;
        final startTime = i * chunkDuration;
        final outputPath = '$outputDir/chunk_${chunkIndex.toString().padLeft(3, '0')}.mp4';

        statusCallback(
            uploadId,
            'chunking',
            'Creating chunk $chunkIndex of $numChunks...',
            0.15 + (0.05 * i / numChunks)
        );

        // FFmpeg command to split video without re-encoding
        // Using -ss before -i is faster for seeking
        // -c copy means "copy streams without re-encoding" to maintain quality
        final command = '-ss $startTime -i "$filePath" -t $chunkDuration -c copy "$outputPath"';

        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final chunkFile = File(outputPath);
          if (await chunkFile.exists()) {
            chunks.add(chunkFile);
          } else {
            throw Exception('Chunk file was not created: $outputPath');
          }
        } else {
          final logs = await session.getLogs();
          throw Exception('Failed to create chunk $chunkIndex: ${logs.join('\n')}');
        }
      }

      return chunks;
    } catch (e) {
      debugPrint('Error creating video chunks: $e');
      throw Exception('Failed to split video into chunks: $e');
    }
  }
}
