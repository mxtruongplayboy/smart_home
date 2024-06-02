import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/login.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    getUserEmail();
  }

  void getUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      userEmail = user?.email; // Get the current user's email
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account"),
        backgroundColor: Colors.deepOrange[800], // Brick color tone for AppBar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.deepOrange[700], // Icon in brick color tone
            ),
            const SizedBox(height: 20),
            Text(
              userEmail ??
                  "No email available", // Display the user's email or a default message
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors
                    .deepOrange[600], // Slightly lighter tone for email text
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Account Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange[900], // Darker tone for text
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.exit_to_app),
              label: const Text('Logout'),
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepOrange[700], // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20), // Padding inside the button
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => LoginPage(cameras: widget.cameras)),
    );
  }
}
