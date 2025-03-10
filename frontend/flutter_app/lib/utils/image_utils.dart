import 'package:flutter/material.dart';

class ImageUtils {
  /// Provides a fallback widget when network images fail to load
  static Widget networkImageWithFallback({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Return a fallback icon when the image fails to load
        return defaultProfileAvatar(width: width, height: height);
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
}
