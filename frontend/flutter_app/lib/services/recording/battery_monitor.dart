import 'package:battery_plus/battery_plus.dart';

class BatteryMonitor {
  static final Battery _battery = Battery();

  // Minimum battery percentage required
  static const int minBatteryPercentage = 15;

  // Check if battery level is sufficient
  static Future<bool> isBatteryLevelSufficient() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      return batteryLevel >= minBatteryPercentage;
    } catch (e) {
      print('Error checking battery level: $e');
      return true; // Assume sufficient on error
    }
  }

  // Get battery charging status
  static Future<bool> isCharging() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging ||
          state == BatteryState.full;
    } catch (e) {
      print('Error checking charging status: $e');
      return false;
    }
  }

  // Stream to monitor battery changes
  static Stream<BatteryState> getBatteryStateStream() {
    return _battery.onBatteryStateChanged;
  }
}