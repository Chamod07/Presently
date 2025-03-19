import 'package:flutter/material.dart';

class ImageUtils {
  /// Provides a fallback widget when network images fail to load
  static Widget networkImageWithFallback({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Create a unique key for the image to prevent rebuild issues
    final imageKey = ValueKey('img_$url');

    return Image.network(
      url,
      key: imageKey,
      width: width,
      height: height,
      fit: fit,
      // Modified headers for better compatibility with Supabase storage
      headers: {
        'Cache-Control': 'max-age=0',
      },
      // Use error builder to provide fallback
      errorBuilder: (context, error, stackTrace) {
        // Only log severe errors, not the 400 errors that still display images
        if (!error.toString().contains('statusCode: 400')) {
          debugPrint(
              'Failed to load image: $url - Error: ${error.toString().split('\n').first}');
        }

        // If error contains 400 but image might still be available, try again with different approach
        if (error.toString().contains('statusCode: 400')) {
          // Return a retry attempt with direct image without custom headers
          return Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) =>
                defaultProfileAvatar(width: width, height: height),
          );
        }

        // Return a fallback icon when the image fails to load
        return defaultProfileAvatar(width: width, height: height);
      },
      // Show loading indicator while the image is loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.grey[400],
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Provides a default profile avatar for use when no image is available
  static Widget defaultProfileAvatar({
    double? width,
    double? height,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[300],
      ),
      child: Icon(
        Icons.person,
        size: (width != null && height != null)
            ? (width < height ? width : height) * 0.5
            : 50,
        color: iconColor ?? Colors.grey[700],
      ),
    );
  }

  /// Returns true if the URL can be loaded, false otherwise
  static Future<bool> isImageUrlAccessible(String url) async {
    try {
      final response = await NetworkImage(url).obtainKey(ImageConfiguration());
      return true;
    } catch (e) {
      return false;
    }
  }
}
