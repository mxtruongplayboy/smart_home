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
  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool isWaitingForResponse = false;

            return Container(
              padding: const EdgeInsets.all(16.0),
              height: 320, // Adjusted height to accommodate label display
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.deviceName,
                      style: Theme.of(context).textTheme.headline6),
                  const SizedBox(height: 20),
                  Text('Toggle Light:',
                      style: Theme.of(context).textTheme.subtitle1),
                  Switch(
                    value: widget.isActive.value,
                    onChanged: (bool value) {
                      Navigator.pop(
                          context); // Close the bottom sheet after toggling
                      setState(() => widget.isActive.value =
                          value); // Update the light status
                    },
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(height: 20),
                  Text('Adjust Brightness:',
                      style: Theme.of(context).textTheme.subtitle1),
                  Stack(
                    children: [
                      Slider(
                        value: widget.isActive.value
                            ? widget.brightness.value.toDouble()
                            : 0,
                        onChanged: widget.isActive.value &&
                                !isWaitingForResponse
                            ? (double newValue) async {
                                setState(() => isWaitingForResponse = true);
                                try {
                                  final url = Uri.parse(
                                      '${widget.apiUrl}intensity=${newValue.round()}');
                                  final response = await http.get(url);

                                  if (response.statusCode == 200) {
                                    // Handle the response if needed
                                    print(
                                        'API call successful: ${response.body}');
                                  } else {
                                    print(
                                        'Failed to call API: ${response.statusCode}');
                                  }
                                } catch (e) {
                                  print('Error calling API: $e');
                                }
                                setState(() {
                                  widget.brightness.value = newValue.round();
                                  isWaitingForResponse = false;
                                });
                              }
                            : null,
                        min: 0,
                        max: 255,
                        divisions: 5, // Allows each integer value as a division
                        label: widget.brightness.value.toString(),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          color: Colors.orange,
                          alignment: Alignment(
                              (widget.brightness.value - 127.5) / 127.5,
                              0), // Position based on brightness
                          child: Text('${widget.brightness.value}',
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
            if (widget.deviceName == 'Dimmer Light') {
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
