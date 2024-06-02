// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:smart_home/views/screens/room_detail.dart';

class RoomWidget extends StatelessWidget {
  const RoomWidget({
    super.key,
    required this.imageUrl,
    required this.nameRoom,
    required this.numDevices,
  });

  final String imageUrl;
  final String nameRoom;
  final int numDevices;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return RoomDetail(
            nameRoom: this.nameRoom,
          );
        }));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        height: 150.0,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
          image:
              DecorationImage(image: AssetImage(imageUrl), fit: BoxFit.cover),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameRoom,
                    style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    '$numDevices devices connected',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.deepOrangeAccent),
            ],
          ),
        ),
      ),
    );
  }
}
