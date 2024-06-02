import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_home/services/firebase_esp8266.dart';
import '../widgets/device_item.dart';
import '../widgets/sensor_item.dart';

class RoomDetail extends StatefulWidget {
  const RoomDetail({super.key, required this.nameRoom});

  final String nameRoom;

  @override
  _RoomDetailState createState() => _RoomDetailState();
}

class _RoomDetailState extends State<RoomDetail> {
  final FirebaseService _firebaseService = FirebaseService();

  ValueNotifier<String> temperature = ValueNotifier('--');
  ValueNotifier<String> humidity = ValueNotifier('--');
  ValueNotifier<bool> homeLedStatus = ValueNotifier(false);
  ValueNotifier<bool> fanStatus = ValueNotifier(false);
  ValueNotifier<int> gardenLedItensity = ValueNotifier(0);
  ValueNotifier<bool> gardenLedItensityStatus = ValueNotifier(false);
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _subscription = _firebaseService.dataStream.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      if (mounted) {
        temperature.value = data['Temperature'] as String? ?? '--';
        humidity.value = data['Humidity'] as String? ?? '--';
        homeLedStatus.value =
            (data['HomeLedStatus'] as String? ?? '--') == 'ON';
        fanStatus.value = (data['Fan_Status'] as String? ?? '--') == 'ON';
        gardenLedItensity.value =
            int.tryParse(data['GardenLedItensity'] as String? ?? '0') ?? 0;
        gardenLedItensityStatus.value =
            (int.tryParse(data['GardenLedItensity'] as String? ?? '0') ?? 0) >
                0;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    temperature.dispose();
    humidity.dispose();
    homeLedStatus.dispose();
    fanStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nameRoom,
            style: const TextStyle(
              color: Colors.deepOrangeAccent,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.grey[100],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Column(children: [
                  if (widget.nameRoom == 'Living Room')
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Sensors',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrangeAccent,
                          )),
                    ),
                  if (widget.nameRoom == 'Living Room')
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: temperature,
                          builder: (_, value, __) => SensorItem(
                              label: 'Temperature',
                              value: '$value°C',
                              icon: Icons.thermostat),
                        ),
                        ValueListenableBuilder<String>(
                          valueListenable: humidity,
                          builder: (_, value, __) => SensorItem(
                              label: 'Humidity',
                              value: '$value%',
                              icon: Icons.water_drop),
                        ),
                      ],
                    ),
                ]),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Devices',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrangeAccent,
                          )),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        if (widget.nameRoom == 'Living Room')
                          DeviceTile(
                            deviceName: 'Fan',
                            icon: FontAwesomeIcons.fan,
                            isActive: fanStatus,
                            apiUrl:
                                'https://crv5jtzg-9999.asse.devtunnels.ms/fan?',
                            brightness: ValueNotifier<int>(0),
                          ),
                        if (widget.nameRoom == 'Living Room' ||
                            widget.nameRoom == 'Bath Room')
                          DeviceTile(
                            deviceName: 'Light',
                            icon: Icons.lightbulb,
                            isActive: homeLedStatus,
                            apiUrl:
                                'https://crv5jtzg-9999.asse.devtunnels.ms/led?location=living-room&',
                            brightness: ValueNotifier<int>(0),
                          ),
                        if (widget.nameRoom == 'Garden')
                          DeviceTile(
                            deviceName: 'Dimmer Light',
                            icon: Icons.lightbulb_circle_outlined,
                            isActive: gardenLedItensityStatus,
                            apiUrl:
                                'https://crv5jtzg-9999.asse.devtunnels.ms/led?location=garden&',
                            brightness: gardenLedItensity,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
