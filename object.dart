import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(BlindAssistantApp(cameras: cameras));
}

class BlindAssistantApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const BlindAssistantApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ObjectDetectionScreen(cameras: cameras),
    );
  }
}

class ObjectDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ObjectDetectionScreen({super.key, required this.cameras});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _controller;
  bool _isDetecting = false;
  final FlutterTts flutterTts = FlutterTts();
  final String apiUrl = "http://127.0.0.1:5000/detect";

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      startDetection();
    });
  }

  void startDetection() async {
    while (mounted) {
      if (!_isDetecting) {
        _isDetecting = true;

        try {
          XFile imageFile = await _controller.takePicture();
          File file = File(imageFile.path);
          List<int> imageBytes = await file.readAsBytes();
          String base64Image = base64Encode(imageBytes);

          var response = await http.post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"image": base64Image}),
          );

          if (response.statusCode == 200) {
            var jsonResponse = json.decode(response.body);
            List detectedObjects = jsonResponse["detections"];

            if (detectedObjects.isNotEmpty) {
              String detectedText = detectedObjects.join(", ");
              await flutterTts.speak(detectedText);
            }
          }
        } catch (e) {
          print("Error: $e");
        }

        _isDetecting = false;
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Object Detection")),
      body: _controller.value.isInitialized
          ? CameraPreview(_controller)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
