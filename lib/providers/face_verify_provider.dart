import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FaceUnlockProvider with ChangeNotifier {
  late CameraController controller;
  late Future<void> initializeControllerFuture;
  int retryCount = 0;
  String? prevFilePath;

  void initCamera(List<CameraDescription> cameras) {
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(frontCamera, ResolutionPreset.medium);
    initializeControllerFuture = controller.initialize();
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> captureAndVerify(BuildContext context, String stage) async {
    await initializeControllerFuture;

    final image = await controller.takePicture();
    final response = await sendImageToServer(image.path, stage);

    if (response['status'] == 'authorized') {
      if (stage == 'authentication') {
        prevFilePath = response['file_path'];
        retryCount = 0;
        notifyListeners();
        Navigator.of(context).pushNamed('/smileVerification');
      } else {
        Navigator.of(context).pushNamed('/success');
      }
    } else {
      if (++retryCount >= 3) {
        Navigator.of(context).pushNamed('/retryLimit');
      } else {
        notifyListeners();
        Navigator.of(context).pushNamed('/retry');
      }
    }
  }

  Future<Map<String, dynamic>> sendImageToServer(
      String imagePath, String stage) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('https://your-server.com/verify'));
    request.fields['user_id'] = 'truong';
    request.fields['stage'] = stage;
    request.fields['retry_count'] = retryCount.toString();
    if (prevFilePath != null && stage == 'check_smile') {
      request.fields['prev_file_path'] = prevFilePath!;
    }
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return json.decode(response.body);
  }
}
