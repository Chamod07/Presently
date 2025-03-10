import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<List<dynamic>> _landmarksController = StreamController<List<dynamic>>.broadcast();
  Timer? _frameTimer;

  // Expose landmarks as a stream for easy consumption
  Stream<List<dynamic>> get landmarksStream => _landmarksController.stream;

  // Connect to WebSocket server
  void connect(String serverUrl) {
    try {
      _channel = IOWebSocketChannel.connect(serverUrl);

      // Listen for landmark data from server
      _channel?.stream.listen(
            (data) {
          try {
            // Parse and add landmarks to the stream
            final landmarks = json.decode(data);
            _landmarksController.add(landmarks);
          } catch (e) {
            print('Error parsing landmarks: $e');
          }
        },
        onError: (error) {
          print('WebSocket connection error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
    }
  }

  // Send image frames to server
  void processFrames(CameraController cameraController) {
    _frameTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (cameraController.value.isInitialized) {
        try {
          final image = await cameraController.takePicture();
          Uint8List imageBytes = await image.readAsBytes();
          String base64Image = base64Encode(imageBytes);

          // Send image to WebSocket
          _channel?.sink.add('data:image/jpeg;base64,$base64Image');
        } catch (e) {
          print('Error processing frame: $e');
        }
      }
    });
  }

  // Close connections and cleanup
  void dispose() {
    _frameTimer?.cancel();
    _channel?.sink.close();
    _landmarksController.close();
  }
}