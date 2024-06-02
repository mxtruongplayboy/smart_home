import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/room_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String displayName = '';

  @override
  void initState() {
    super.initState();
    if (user != null) {
      displayName = user?.displayName ?? 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('HomeFace Secure',
            style: TextStyle(
              color: Colors.deepOrangeAccent,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $displayName!',
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8.0,
            ),
            const Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    RoomWidget(
                      imageUrl: './assets/images/Living Room.webp',
                      nameRoom: 'Living Room',
                      numDevices: 3,
                    ),
                    RoomWidget(
                      imageUrl: './assets/images/kitchen room.png',
                      nameRoom: 'Kitchen Room',
                      numDevices: 0,
                    ),
                    RoomWidget(
                      imageUrl: './assets/images/Bed Room.jpg',
                      nameRoom: 'Bed Room',
                      numDevices: 0,
                    ),
                    RoomWidget(
                      imageUrl: './assets/images/Bath Room.jpg',
                      nameRoom: 'Bath Room',
                      numDevices: 0,
                    ),
                    RoomWidget(
                      imageUrl: './assets/images/Garden.webp',
                      nameRoom: 'Garden',
                      numDevices: 0,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
