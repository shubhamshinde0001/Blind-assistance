import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class LiveTextDetectionScreen extends StatefulWidget {
  const LiveTextDetectionScreen({super.key});

  @override
  _LiveTextDetectionScreenState createState() => _LiveTextDetectionScreenState();
}

class _LiveTextDetectionScreenState extends State<LiveTextDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String detectedText = "Detecting text...";
  bool isProcessing = false;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    initializeCamera();
    flutterTts.setLanguage("en-US");
    flutterTts.setSpeechRate(0.5); // Adjust speech rate if needed
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras![0], ResolutionPreset.medium);
    await _cameraController!.initialize();

    if (mounted) {
      setState(() {});
      startLiveDetection(); // Start detecting text continuously
    }
  }

  Future<void> startLiveDetection() async {
    while (mounted) {
      if (!isProcessing) {
        isProcessing = true;
        await captureAndSendFrame();
        await Future.delayed(Duration(milliseconds: 500)); // Adjust for real-time speed
        isProcessing = false;
      }
    }
  }

  Future<void> captureAndSendFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      XFile imageFile = await _cameraController!.takePicture();
      Uint8List imageBytes = await imageFile.readAsBytes();

      Uri url = Uri.parse('http://127.0.0.1:5002/process_image');
      var request = http.MultipartRequest('POST', url);
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'frame.jpg'));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = jsonDecode(responseData);

      String newText = jsonData['text'] ?? 'No text detected.';

      if (newText.isNotEmpty && newText != detectedText) {
        setState(() {
          detectedText = newText;
        });

        // Speak the detected text
        await flutterTts.speak(newText);
      }
    } catch (e) {
      setState(() {
        detectedText = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Text Detection')),
      body: Column(
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Expanded(child: CameraPreview(_cameraController!)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              detectedText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
