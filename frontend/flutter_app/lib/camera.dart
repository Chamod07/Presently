// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';

// class RecordingScreen extends StatefulWidget {
//   const RecordingScreen({super.key});

//  @override
 // _RecordingScreenState createState() => _RecordingScreenState();
//}

//class _RecordingScreenState extends State<RecordingScreen> {
 // CameraController? _cameraController;
 // bool _isRecording = false;

  //@override
  //void initState() {
   // super.initState();
   // _initializeCamera();
  //}

 // Future<void> _initializeCamera() async {
  //  final cameras = await availableCameras();
 //   _cameraController = CameraController(cameras[0], ResolutionPreset.high);

 //   await _cameraController?.initialize();
 //   if (mounted) {
  //    setState(() {});
  //  }
 // }

 // void _startRecording() async {
  //  if (_cameraController != null) {
  //    await _cameraController?.startVideoRecording();
  //    setState(() {
   //     _isRecording = true;
   //   });
   // }
  //}

 // void _stopRecording() async {
  //  if (_cameraController != null) {
  //    await _cameraController?.stopVideoRecording();
  //    setState(() {
  //      _isRecording = false;
  //    });
  //  }
 // }

  //@override
  //Widget build(BuildContext context) {
  //  if (_cameraController == null || !_cameraController!.value.isInitialized) {
  //    return Center(child: CircularProgressIndicator());
  //  }

  //  return Scaffold(
   //   appBar: AppBar(
   //     title: Text("Class Presentation"),
   //     backgroundColor: Colors.purple,
   //   ),
    //  body: Stack(
    //    children: [
     //     CameraPreview(_cameraController!),
       //   Positioned(
         //   bottom: 50,
           // left: MediaQuery.of(context).size.width / 2 - 35,
            //child: FloatingActionButton(
            //  onPressed: _isRecording ? _stopRecording : _startRecording,
            //  backgroundColor: Colors.red,
            //  child: Icon(_isRecording ? Icons.stop : Icons.circle),
 //           ),
   //       ),
     //   ],
  //    ),
  //  );
  //}

 // @override
  //void dispose() {
  //  _cameraController?.dispose();
   // super.dispose();
//  }
// }