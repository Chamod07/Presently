enum VideoQuality {
  low,
  medium,
  high,
  original
}

class VideoQualityPreset {
  final VideoQuality quality;
  final int bitrate;       // in Kbps
  final int width;         // in pixels
  final int height;        // in pixels
  final double framerate;  // in fps

  const VideoQualityPreset({
    required this.quality,
    required this.bitrate,
    required this.width,
    required this.height,
    required this.framerate,
  });

  // Get preset based on quality enum
  static VideoQualityPreset getPreset(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.low:
        return VideoQualityPreset(
          quality: VideoQuality.low,
          bitrate: 500, // 500 Kbps
          width: 480,   // 480p
          height: 360,
          framerate: 24.0,
        );
      case VideoQuality.medium:
        return VideoQualityPreset(
          quality: VideoQuality.medium,
          bitrate: 1500, // 1.5 Mbps
          width: 720,    // 720p
          height: 480,
          framerate: 30.0,
        );
      case VideoQuality.high:
        return VideoQualityPreset(
          quality: VideoQuality.high,
          bitrate: 3000, // 3 Mbps
          width: 1280,   // 1080p
          height: 720,
          framerate: 30.0,
        );
      case VideoQuality.original:
        return VideoQualityPreset(
          quality: VideoQuality.original,
          bitrate: 6000, // 6 Mbps (or higher, depends on source)
          width: 1920,   // Full HD
          height: 1080,
          framerate: 30.0,
        );
    }
  }

  // Convert to ffmpeg parameters (for video processing)
  Map<String, String> toFfmpegParams() {
    return {
      'bitrate': '${bitrate}k',
      'size': '${width}x${height}',
      'framerate': framerate.toString(),
    };
  }

  // User-friendly description
  String getDescription() {
    switch (quality) {
      case VideoQuality.low:
        return '480p (Low) - Good for slow connections';
      case VideoQuality.medium:
        return '720p (Medium) - Balanced quality';
      case VideoQuality.high:
        return '1080p (High) - Better quality, requires good connection';
      case VideoQuality.original:
        return 'Original Quality - Highest quality, requires excellent connection';
    }
  }
}