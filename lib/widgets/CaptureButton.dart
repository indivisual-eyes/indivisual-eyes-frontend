import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' as developer;
import 'package:image/image.dart' as img;

class CaptureButton extends StatelessWidget {
  final CameraController controller;
  final Future<void> initializeControllerFuture;
  final String cvdType;

  const CaptureButton({
    super.key,
    required this.controller,
    required this.initializeControllerFuture,
    required this.cvdType
  });


  Future<void> _captureAndProcessImage(BuildContext context) async {
    try {
      await initializeControllerFuture;

      final image = await controller.takePicture();
      if (!context.mounted) return;

      final rotatedFile = await fixImageRotation(File(image.path));

      var req = http.MultipartRequest(
        "POST", 
        Uri.parse("https://mcs.drury.edu/mirror/image"),
      );
      req.fields["cvd_type"] = cvdType;
      developer.debugPrint("CVD Type: $cvdType");
      req.files.add(
        await http.MultipartFile.fromPath("image", rotatedFile.path),
      );
      
      final res = await req.send();
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        var filename = '${dir.path}/response_image${Random().nextInt(100)}.png';
        final file = File(filename);
        await file.writeAsBytes(await res.stream.toBytes());

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(imagePath: file.path),
          ),
        );
      }
    } catch (e) {
      developer.debugPrint("Error capturing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _captureAndProcessImage(context),
      child: const Icon(Icons.camera_alt),
    );
  }
}

/// Fix image rotation by rotating it **180 degrees** before displaying
Future<File> fixImageRotation(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return file;

    // Always rotate the image by 180 degrees
    final rotatedImage = img.copyRotate(image,angle:180);

    // Save the rotated image back to the file
    final newFile = File(file.path)..writeAsBytesSync(img.encodeJpg(rotatedImage));
    return newFile;
  } catch (e) {
    // developer.log("Error rotating image: $e");
    return file; // Return original file if rotation fails
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: FutureBuilder<File>(
        future: fixImageRotation(File(imagePath)), // Ensure rotation before displaying
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return Image.file(snapshot.data!);
          }
        },
      ),
    );
  }
}
