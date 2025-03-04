import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioFilePath;

  Future<void> initialize() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> startRecording() async {
    final directory = await getTemporaryDirectory();
    _audioFilePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    
    await _recorder.startRecorder(
      toFile: _audioFilePath,
      codec: Codec.aacADTS,
    );
    
    _isRecording = true;
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    _isRecording = false;
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
  }

  bool get isRecording => _isRecording;
  String? get audioFilePath => _audioFilePath;
}