import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeviceTile extends StatefulWidget {
  final String deviceName;
  final IconData icon;
  final ValueNotifier<bool> isActive;
  final String apiUrl;
  final ValueNotifier<int> brightness; // Default brightness

  DeviceTile({
    super.key,
    required this.deviceName,
    required this.icon,
    required this.isActive,
    required this.apiUrl,
    required this.brightness,
  });

  @override
  _DeviceTileState createState() => _DeviceTileState();
}

class _DeviceTileState extends State<DeviceTile> {
  late Future<List<Map<String, dynamic>>> schedule;

  @override
  void initState() {
    super.initState();
    schedule = _fetchSchedule();
  }

  Future<List<Map<String, dynamic>>> _fetchSchedule() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('ScheduledJobs').get();
    return querySnapshot.docs.map((doc) {
      return {
        'task_id': doc.id,
        'action': doc['action'],
        'hour': doc['hour'],
        'minute': doc['minute'],
        'is_active': doc['is_active'],
      };
    }).toList();
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool isWaitingForResponse = false;

            var deviceActions = {
              'Light': 'turn on led home',
              'Fan': 'turn on fan',
              'Dimmer Light': 'turn on led garden',
            };

            // Define a function to update the schedule using an API call
            void updateSchedule(Map<String, dynamic> scheduleItem, int newHour,
                int newMinute, bool newIsActive) async {
              setState(() => isWaitingForResponse = true);
              final response = await http.post(
                Uri.parse(
                    'https://crv5jtzg-9999.asse.devtunnels.ms/update-schedule'),
                headers: <String, String>{
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(<String, dynamic>{
                  'task_id': scheduleItem['task_id'],
                  'hour': newHour,
                  'minute': newMinute,
                  'is_active': newIsActive ? 1 : 0
                }),
              );
              if (response.statusCode == 200) {
                print('Schedule update successful: ${response.body}');
                setState(() {
                  scheduleItem['hour'] = newHour;
                  scheduleItem['minute'] = newMinute;
                  scheduleItem['is_active'] = newIsActive ? 1 : 0;
                });
              } else {
                print('Failed to update schedule: ${response.statusCode}');
              }
              setState(() => isWaitingForResponse = false);
            }

            void showTimeEditDialog(Map<String, dynamic> scheduleItem) {
              TextEditingController hourController =
                  TextEditingController(text: scheduleItem['hour'].toString());
              TextEditingController minuteController = TextEditingController(
                  text: scheduleItem['minute'].toString());

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Edit Time'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: hourController,
                          decoration: InputDecoration(labelText: 'Hour (0-23)'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: minuteController,
                          decoration:
                              InputDecoration(labelText: 'Minute (0-59)'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          int newHour = int.parse(hourController.text);
                          int newMinute = int.parse(minuteController.text);
                          updateSchedule(scheduleItem, newHour, newMinute,
                              scheduleItem['is_active'] == 1);
                          Navigator.of(context).pop();
                        },
                        child: Text('Update'),
                      ),
                    ],
                  );
                },
              );
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: schedule,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No schedules found'));
                }

                var filteredSchedules = snapshot.data!
                    .where((item) =>
                        deviceActions[widget.deviceName]
                            ?.contains(item['action']) ??
                        false)
                    .toList();

                return Container(
                  padding: const EdgeInsets.all(16.0),
                  height: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.deviceName,
                          style: Theme.of(context).textTheme.headline6),
                      const SizedBox(height: 20),
                      Text('Toggle Device:',
                          style: Theme.of(context).textTheme.subtitle1),
                      Switch(
                        value: widget.isActive.value,
                        onChanged: (bool value) {
                          Navigator.pop(context);
                          setState(() => widget.isActive.value = value);
                          _toggleActive(value);
                        },
                        activeColor: Colors.orange,
                      ),
                      const SizedBox(height: 20),
                      if (widget.deviceName == 'Dimmer Light')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Adjust Brightness:',
                                style: Theme.of(context).textTheme.subtitle1),
                            Slider(
                              value: widget.isActive.value
                                  ? widget.brightness.value.toDouble()
                                  : 0,
                              onChanged: widget.isActive.value &&
                                      !isWaitingForResponse
                                  ? (double newValue) async {
                                      setState(
                                          () => isWaitingForResponse = true);
                                      final url = Uri.parse(
                                          '${widget.apiUrl}intensity=${newValue.round()}');
                                      final response = await http.get(url);
                                      if (response.statusCode == 200) {
                                        print(
                                            'API call successful: ${response.body}');
                                      } else {
                                        print(
                                            'Failed to call API: ${response.statusCode}');
                                      }
                                      setState(() {
                                        widget.brightness.value =
                                            newValue.round();
                                        isWaitingForResponse = false;
                                      });
                                    }
                                  : null,
                              min: 0,
                              max: 255,
                              divisions: 255,
                              label: widget.brightness.value.toString(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Scheduled Actions:',
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredSchedules.length,
                          itemBuilder: (context, index) {
                            var scheduleItem = filteredSchedules[index];
                            bool isActive = scheduleItem['is_active'] == 1;
                            return ListTile(
                              leading: Icon(
                                isActive
                                    ? Icons.lightbulb
                                    : Icons.lightbulb_outline,
                                color: isActive ? Colors.orange : Colors.grey,
                              ),
                              title: Text(scheduleItem['action']),
                              subtitle: Text(
                                  'Time: ${scheduleItem['hour'].toString().padLeft(2, '0')}:${scheduleItem['minute'].toString().padLeft(2, '0')}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () =>
                                        showTimeEditDialog(scheduleItem),
                                  ),
                                  Switch(
                                    value: isActive,
                                    onChanged: (bool value) {
                                      updateSchedule(
                                          scheduleItem,
                                          scheduleItem['hour'],
                                          scheduleItem['minute'],
                                          value);
                                    },
                                    activeColor: Colors.orange,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _toggleActive(bool newValue) async {
    var url = Uri.parse(widget.apiUrl);
    if (widget.deviceName == 'Light' || widget.deviceName == 'Fan') {
      final statusValue = newValue ? '1' : '0';
      url = Uri.parse('${widget.apiUrl}status=$statusValue');
      print('API call: $url');
    } else if (widget.deviceName == 'Dimmer Light') {
      final brightnessValue = newValue ? 255 : 0;
      url = Uri.parse('${widget.apiUrl}intensity=$brightnessValue');
      print('API call: $url');
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Handle the response if needed
        print('API call successful: ${response.body}');
      } else {
        print('Failed to call API: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API: $e');
    }
    widget.isActive.value = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isActive,
      builder: (context, isActive, child) {
        return InkWell(
          onTap: () {
            if (widget.deviceName == 'Dimmer Light' ||
                widget.deviceName == 'Light' ||
                widget.deviceName == 'Fan') {
              _showDetailsBottomSheet(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: isActive ? Colors.orange : Colors.grey,
                      size: 40.0,
                    ),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      onChanged: (bool newValue) async {
                        await _toggleActive(newValue);
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.deviceName,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.deviceName == 'Dimmer Light'
                      ? 'Brightness: ${widget.brightness.value}'
                      : isActive
                          ? 'ON'
                          : 'OFF',
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
