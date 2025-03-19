import 'package:flutter/material.dart';
import '../../services/recording/recording_constraints.dart';

class RecordingTimer extends StatelessWidget {
  final int durationSeconds;
  final bool isRecording;

  const RecordingTimer({
    Key? key,
    required this.durationSeconds,
    required this.isRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');

    // Calculate time remaining
    final timeRemaining = RecordingConstraints.maxRecordingDuration - durationSeconds;
    final isWarning = RecordingConstraints.shouldShowWarning(durationSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRecording
            ? (isWarning ? const Color(0xCCFF9800): const Color(0xB3FF0000))
            : Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isWarning ? Colors.orange : Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isRecording && isWarning) ...[
            const SizedBox(width: 8),
            Text(
              '${(timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(timeRemaining % 60).toString().padLeft(2, '0')} left',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}