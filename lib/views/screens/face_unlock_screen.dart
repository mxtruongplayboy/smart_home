import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class FaceUnlockScreen extends StatefulWidget {
  final String selectedDoor;
  final List<CameraDescription> cameras;

  const FaceUnlockScreen(
      {super.key, required this.selectedDoor, required this.cameras});

  @override
  _FaceUnlockScreenState createState() => _FaceUnlockScreenState();
}

class _FaceUnlockScreenState extends State<FaceUnlockScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int retryCount = 0;
  String? prevFilePath;
  bool isAuthenticated = false;
  String instruction = "Look straight into the camera and hold still.";

  User? user = FirebaseAuth.instance.currentUser;
  String user_id = '';

  @override
  void initState() {
    super.initState();
    initCamera();
    if (user != null) {
      user_id = user?.displayName ?? 'User';
    }
  }

  void initCamera() {
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> captureAndVerify() async {
    String stage = isAuthenticated ? 'check_smile' : 'authentication';
    // Update instruction based on stage
    setState(() {
      instruction = stage == 'authentication'
          ? "Look straight into the camera and hold still."
          : "Smile and look straight into the camera.";
    });

    // Ensure camera is initialized before capturing
    await _initializeControllerFuture;

    // Taking a picture
    final image = await _controller.takePicture();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on tap outside
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.blue),
              SizedBox(width: 10),
              Text("Processing"),
            ],
          ),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Please wait...')
            ],
          ),
        );
      },
    );

    // Sending image to server
    final response = await sendImageToServer(image.path, stage);

    // Dismiss the loading dialog
    Navigator.of(context).pop();

    if (response['status'] == 'authorized' && stage == 'authentication') {
      setState(() {
        prevFilePath = response['file_path'];
        retryCount = 0;
        isAuthenticated = true;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 10),
                Text("Success"),
              ],
            ),
            content: const Text(
                "Authentication complete, please proceed to Step 2: Smile"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Continue",
                    style: TextStyle(color: Colors.green)),
              ),
            ],
          );
        },
      );
    } else if (response['status'] == 'smiling' && stage == 'check_smile') {
      showUnlockSuccessDialog();
    } else {
      if (++retryCount >= 3) {
        showRetryLimitReachedDialog();
      } else {
        showRetryDialog("Face not recognized, please try again.");
      }
    }
  }

  void showRetryDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text("Try Again"),
            ],
          ),
          content: Text("$message Attempt $retryCount of 3"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showUnlockSuccessDialog() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on tap outside
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.blue),
              SizedBox(width: 10),
              Text("Processing"),
            ],
          ),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Please wait...')
            ],
          ),
        );
      },
    );

    // Call the door API
    final response = await callDoorApi();

    // Dismiss the loading dialog
    Navigator.of(context).pop();

    if (response['status'] == 'success') {
      _controller.dispose(); // Dispose of the camera controller
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_open, color: Colors.green),
                SizedBox(width: 10),
                Text("Unlock Successful"),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Face verification complete! Door unlocked.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Icon(Icons.check_circle_outline, color: Colors.green, size: 50),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // This will exit the screen
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 10),
                Text("Unlock Failed"),
              ],
            ),
            content: const Text("Failed to unlock the door. Please try again."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // This will exit the screen
                },
                child: const Text("OK", style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> showRetryLimitReachedDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 10),
              Text("Error"),
            ],
          ),
          content: const Text("Retry limit reached. Please start over."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // This will exit the screen
              },
              child: const Text("OK", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> callDoorApi() async {
    final response = await http.get(
      Uri.parse('https://crv5jtzg-9999.asse.devtunnels.ms/door?status=1'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {
        'status': 'error',
        'message': 'Failed to unlock the door',
      };
    }
  }

  Future<Map<String, dynamic>> sendImageToServer(
      String imagePath, String stage) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('https://crv5jtzg-9999.asse.devtunnels.ms/verify'));
    request.fields['user_id'] = user_id;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedDoor,
          style: const TextStyle(
            color: Colors.deepOrangeAccent,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepOrangeAccent),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      CameraPreview(_controller),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrangeAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 12.0),
                            ),
                            onPressed: () => captureAndVerify(),
                            child: const Text(
                              'Verify Identity',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            instruction,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrangeAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
