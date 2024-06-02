import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/services/firebase_esp8266.dart';
import 'face_unlock_screen.dart';

class DoorSelectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const DoorSelectionScreen({super.key, required this.cameras});

  @override
  State<DoorSelectionScreen> createState() => _DoorSelectionScreenState();
}

class _DoorSelectionScreenState extends State<DoorSelectionScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late StreamSubscription _dataSubscription;
  String doorStatus = 'CLOSE';
  late Future<List<Map<String, dynamic>>> historyData;

  @override
  void initState() {
    super.initState();
    _fetchData();
    historyData = _fetchHistoryData();
  }

  void _fetchData() {
    _dataSubscription = _firebaseService.dataStream.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      if (mounted) {
        setState(() {
          doorStatus = data['Door_Status'] ?? 'CLOSE';
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryData() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('OpenDoorHistory')
        .orderBy('open_at', descending: true)
        .get();
    return querySnapshot.docs.map((doc) {
      return {
        'date': doc['open_at'].toDate().toString(),
        'imageUrl': doc['image_url'],
        'user': doc['user_id'],
        'stage': doc['stage'],
      };
    }).toList();
  }

  void _closeDoor() async {
    final response = await http.get(
        Uri.parse('https://crv5jtzg-9999.asse.devtunnels.ms/door?status=0'));
    if (response.statusCode == 200 && mounted) {
      // Check if mounted before updating UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Door is now closed!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to close the door!')),
      );
    }
  }

  Future<void> _showCloseDoorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Door is Open'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Would you like to close the door?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _closeDoor();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Select a Door",
          style: TextStyle(
            color: Colors.deepOrangeAccent,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDoorList(),
            const Divider(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorList() {
    final List<Map<String, dynamic>> doors = [
      {
        'name': 'Front Door',
        'icon': doorStatus == 'OPEN'
            ? Icons.meeting_room_rounded
            : Icons.door_front_door,
        'color': doorStatus == 'OPEN' ? Colors.green : Colors.deepOrange,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: doors.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            leading: Icon(
              doors[index]['icon'],
              color: doors[index]['color'],
              size: 30.0,
            ),
            title: Text(
              doors[index]['name'],
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: doorStatus == 'OPEN'
                ? () => _showCloseDoorDialog()
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceUnlockScreen(
                          selectedDoor: doors[index]['name'],
                          cameras: widget.cameras,
                        ),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Open Door History",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrangeAccent,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('OpenDoorHistory')
              .orderBy('open_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return const Text('No data available');
            } else {
              return ListView.builder(
                shrinkWrap: true,
                physics:
                    NeverScrollableScrollPhysics(), // Prevents scrolling within the nested ListView
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading:
                        Image.network(data['image_url'], width: 50, height: 50),
                    title: Text(data['user_id']),
                    subtitle: Text(data['open_at'].toDate().toString()),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      // Navigate to detail screen if needed
                    },
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }
}
