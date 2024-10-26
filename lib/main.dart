import 'package:cameracapture/components/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(CameraCaptureApp(camera: firstCamera));
}

class CameraCaptureApp extends StatelessWidget {
  final CameraDescription camera;

  const CameraCaptureApp({Key? key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(camera: camera),
    );
  }
}
