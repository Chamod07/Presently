import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:disk_space_plus/disk_space_plus.dart';

class StorageCheck {
  // Required free space in MB
  static const int requiredFreeSpaceMB = 200;

  // Check if there's enough storage space
  static Future<bool> hasEnoughStorageSpace() async {
    try {
      double? freeSpace;

      if (Platform.isAndroid || Platform.isIOS) {
        freeSpace = await DiskSpacePlus.getFreeDiskSpace;
        return freeSpace != null && freeSpace >= requiredFreeSpaceMB;
      } else {
        // Fallback for other platforms
        final directory = await getApplicationDocumentsDirectory();
        final stat = await directory.stat();
        final freeBytes = stat.size;
        return freeBytes >= requiredFreeSpaceMB * 1024 * 1024;
      }
    } catch (e) {
      print('Error checking storage space: $e');
      return false; // Assume not enough space on error
    }
  }

  // Get a user-friendly message about storage space
  static Future<String> getStorageMessage() async {
    try {
      double? freeSpace = await DiskSpacePlus.getFreeDiskSpace;
      return 'Free space: ${freeSpace?.toStringAsFixed(2) ?? "Unknown"} MB';
    } catch (e) {
      return 'Unable to determine free space';
    }
  }
}