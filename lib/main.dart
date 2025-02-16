import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  const TakePictureScreen({super.key, required this.camera});
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var random = Random();

          try {
            await _initializeControllerFuture;
            // Take a picture
            final image = await _controller.takePicture();
            if (!context.mounted) return;

            // Send the image to the backend
            var req = http.MultipartRequest("POST", Uri.parse("https://mcs.drury.edu/mirror/image"));
            req.fields["cvd_type"] = "Protanopia";
            req.files.add(await http.MultipartFile.fromPath("image", image.path));
            final res = await req.send();

            if (res.statusCode == 200) {
              // Save the image returned from the backend to the device
              final dir = await getTemporaryDirectory();
              var filename = '${dir.path}/response_image${random.nextInt(100)}.png';
              final file = File(filename);
              await file.writeAsBytes(await res.stream.toBytes());

              // Show the image returned from the backend
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(imagePath: file.path),
                ),
              );
            }
          } catch (e) {
            developer.log(e.toString());
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// Screen to show the image returned from the backend
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}
