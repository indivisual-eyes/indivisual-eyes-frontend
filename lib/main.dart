import 'dart:async';
import 'dart:io';
// import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Custom imports
import 'widgets/CaptureButton.dart';
import 'widgets/FilterMenu.dart';

// Ignore website certificates
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// Run the app
Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final camera = (await availableCameras()).first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(camera: camera),
    ),
  );
}

// Screen that shows camera preview and takes a picture
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  const TakePictureScreen({super.key, required this.camera});
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}



class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String cvdType = 'Protanopia'; 
  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false, // May help with rotation issues
    );
    _initializeControllerFuture = _controller.initialize();
            
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void updateType(String newType) {
    setState(() {
      cvdType = newType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a Picture')),
      body: FutureBuilder<void>(
        
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    
      bottomNavigationBar: BottomAppBar(
        child:Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // adjust spacing
          children: [
            CaptureButton(controller: _controller, initializeControllerFuture: _initializeControllerFuture, cvdType: cvdType),
            FilterMenu(onTypeChanged: updateType),
          ]
        ),
      ),
    );
  }
}

