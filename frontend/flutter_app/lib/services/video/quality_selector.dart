import '../network/network_bandwidth_monitor.dart';
import 'video_quality_presets.dart';

class QualitySelector {
  // Get recommended quality based on network
  static VideoQuality getRecommendedQuality(NetworkQuality networkQuality) {
    switch (networkQuality) {
      case NetworkQuality.none:
      // Offline upload (will be stored for later)
        return VideoQuality.low;
      case NetworkQuality.poor:
        return VideoQuality.low;
      case NetworkQuality.moderate:
        return VideoQuality.medium;
      case NetworkQuality.good:
        return VideoQuality.high;
      case NetworkQuality.excellent:
        return VideoQuality.original;
    }
  }

  // Estimate upload time based on file size and network quality
  static double estimateUploadTime(int fileSizeInBytes, NetworkQuality networkQuality) {
    if (networkQuality == NetworkQuality.none) {
      return double.infinity; // Cannot upload
    }

    // Get average upload speed based on network quality (in KB/s)
    // Note: Upload speeds are typically slower than download speeds
    double uploadSpeedKBps;
    switch (networkQuality) {
      case NetworkQuality.poor:
        uploadSpeedKBps = 30; // ~240 Kbps
        break;
      case NetworkQuality.moderate:
        uploadSpeedKBps = 100; // ~800 Kbps
        break;
      case NetworkQuality.good:
        uploadSpeedKBps = 250; // ~2 Mbps
        break;
      case NetworkQuality.excellent:
        uploadSpeedKBps = 625; // ~5 Mbps
        break;
      default:
        uploadSpeedKBps = 10;
    }

    // Calculate estimated time in seconds
    double fileSizeKB = fileSizeInBytes / 1024;
    return fileSizeKB / uploadSpeedKBps;
  }

  // Format estimated time to user-friendly string
  static String formatEstimatedTime(double timeInSeconds) {
    if (timeInSeconds == double.infinity) {
      return 'Not available offline';
    }

    if (timeInSeconds < 60) {
      return '${timeInSeconds.round()} seconds';
    } else if (timeInSeconds < 3600) {
      int minutes = (timeInSeconds / 60).floor();
      int seconds = (timeInSeconds % 60).round();
      return '$minutes min $seconds sec';
    } else {
      int hours = (timeInSeconds / 3600).floor();
      int minutes = ((timeInSeconds % 3600) / 60).floor();
      return '$hours hr $minutes min';
    }
  }
}