import 'package:flutter/material.dart';
import '../../services/recording/constraints_manager.dart';

class ConstraintWarning extends StatelessWidget {
  final ConstraintViolation violation;

  const ConstraintWarning({Key? key, required this.violation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (violation) {
      case ConstraintViolation.insufficientStorage:
        return _buildWarning(
            'Not enough storage space',
            'Free up at least 200MB to record presentations',
            Icons.storage,
            Colors.red
        );
      case ConstraintViolation.lowBattery:
        return _buildWarning(
            'Battery too low',
            'Please connect your device to a charger',
            Icons.battery_alert,
            Colors.orange
        );
      case ConstraintViolation.maxDurationExceeded:
        return _buildWarning(
            'Maximum recording time reached',
            'Recording will automatically stop now',
            Icons.timer_off,
            Colors.amber
        );
      case ConstraintViolation.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWarning(String title, String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}