import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/models/BottomNavItem.dart';
import 'package:smart_home/views/screens/account_screen.dart';
import 'package:smart_home/views/screens/face_verify.dart';
import 'package:smart_home/views/screens/home_screen.dart';

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MyHomePage({super.key, required this.cameras});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavItem> bottomNavItems = [
    BottomNavItem(
      icon: const Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavItem(
      label: 'Face Verify',
      icon: const Icon(Icons.verified_user_outlined),
    ),
    BottomNavItem(
      icon: const Icon(Icons.grid_view_rounded),
      label: 'Devices',
    ),
    BottomNavItem(
      icon: const Icon(Icons.account_circle_rounded),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          DoorSelectionScreen(cameras: widget.cameras),
          const Center(child: Text('History')),
          AccountScreen(cameras: widget.cameras),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.deepOrangeAccent,
        unselectedFontSize: 10,
        selectedFontSize: 10,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          for (var i = 0; i < bottomNavItems.length; i++)
            BottomNavigationBarItem(
              icon: bottomNavItems.elementAt(i).icon ?? const Icon(Icons.error),
              label: bottomNavItems.elementAt(i).label,
            )
        ],
      ),
    );
  }
}
