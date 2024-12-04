import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'package:intl/intl.dart';

void main() {
  tz.initializeTimeZones(); // Initialize timezone data
  runApp(TimezoneConverterApp());
}

class TimezoneConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeSync',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF010817), // Set background color
        primaryColor: Color(0xFF010817),
      ),
      home: TimezoneConverterScreen(),
    );
  }
}

class TimezoneConverterScreen extends StatefulWidget {
  @override
  _TimezoneConverterScreenState createState() =>
      _TimezoneConverterScreenState();
}

class _TimezoneConverterScreenState extends State<TimezoneConverterScreen> {
  late Timer _timer;
  String _localTime = '';
  String? _selectedTimezone;
  late List<String> _timezones;
  List<String> _filteredTimezones = [];
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _selectedTimezonesList = [];
  Map<String, Timer> _timezoneTimers = {}; // To store timers for each timezone

  @override
  void initState() {
    super.initState();
    _initializeTimezones(); // Fetch all timezones
    _updateLocalTime(); // Set initial time
    _startClock(); // Start the clock
  }

  @override
  void dispose() {
    _timer.cancel(); // Stop the global timer
    _timezoneTimers.values.forEach((timer) =>
        timer.cancel()); // Cancel individual timers
    _searchController.dispose();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateLocalTime();
    });
  }

  void _updateLocalTime() {
    final now = DateTime.now();
    setState(() {
      _localTime = DateFormat('hh:mm a').format(
          now); // Format time as 12-hour with AM/PM
    });

    // Only update converted time for the selected timezones
    _selectedTimezonesList.forEach((timezone) {
      _convertTime(
          timezone['timezone']!); // Update the converted time dynamically
    });
  }

  Future<void> _initializeTimezones() async {
    // Fetch all available timezones
    setState(() {
      _timezones = tz.timeZoneDatabase.locations.keys.toList();
      _filteredTimezones = _timezones; // Initialize filtered list
    });
  }

  void _convertTime(String targetTimezone) {
    try {
      final now = DateTime.now();
      final targetLocation = tz.getLocation(targetTimezone);
      final convertedTime = tz.TZDateTime.from(now, targetLocation);

      // Check if the timezone is already in the list, if not, add it
      if (!_selectedTimezonesList.any((timezone) =>
      timezone['timezone'] == targetTimezone)) {
        setState(() {
          _selectedTimezonesList.add({
            'timezone': targetTimezone,
            'time': DateFormat('hh:mm a').format(convertedTime),
            // Format time as 12-hour with AM/PM
          });
        });

        // Start a new timer for the new timezone
        _timezoneTimers[targetTimezone] =
            Timer.periodic(Duration(seconds: 1), (timer) {
              _convertTime(targetTimezone);
            });
      } else {
        // If the timezone is already in the list, just update its time
        setState(() {
          for (var timezone in _selectedTimezonesList) {
            if (timezone['timezone'] == targetTimezone) {
              timezone['time'] = DateFormat('hh:mm a').format(convertedTime);
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _selectedTimezonesList.add({
          'timezone': targetTimezone,
          'time': 'Error!',
        });
      });
    }
  }

  void _removeTimezone(String timezone) {
    setState(() {
      // Remove the timezone from the list
      _selectedTimezonesList.removeWhere((timezoneMap) =>
      timezoneMap['timezone'] == timezone);

      // Cancel the timer associated with this timezone
      _timezoneTimers[timezone]?.cancel();
      _timezoneTimers.remove(timezone); // Remove from the map of active timers
    });
  }

  void _showTimezonePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void _filterTimezones(String query) {
              setModalState(() {
                _filteredTimezones = _timezones
                    .where((timezone) =>
                    timezone.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              });
            }

            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.75,
              color: Color(0xFF010817), // Dropdown background color
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterTimezones,
                    style: TextStyle(color: Colors.white), // Set the input text color to white
                    decoration: InputDecoration(
                      hintText: 'Search Timezones',
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.white), // Set hint text color to white
                    ),
                  ),

                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredTimezones.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _filteredTimezones[index],
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedTimezone = _filteredTimezones[index];
                              _convertTime(_filteredTimezones[index]);
                            });
                            Navigator.pop(context);
                          },
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF010817),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          // Center content horizontally
          children: [
            Image.asset(
              'assets/logo.png', // Replace with the path to your logo image
              height: 30,
            ),
            SizedBox(width: 10),
            Text(
              'TimeSync',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          // Keep top alignment
          crossAxisAlignment: CrossAxisAlignment.center,
          // Center content horizontally
          children: [
            // Left-aligned Local Time Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // Space between the items
              children: [
                Text(
                  'Local Time',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _localTime,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Centered Add Button for Timezone Selection (White Button with text color #010817)
            Center(
              child: ElevatedButton(
                onPressed: _showTimezonePicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: Text(
                  'Add Timezone',
                  style: TextStyle(
                      color: Color(0xFF010817)), // Text color #010817
                ),
              ),
            ),
            SizedBox(height: 16),

            // Display List of Timezones and their Corresponding Times
            Expanded(
              child: ListView.builder(
                itemCount: _selectedTimezonesList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    title: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTimezonesList[index]['timezone']!,
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              _selectedTimezonesList[index]['time']!,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            _removeTimezone(_selectedTimezonesList[index]['timezone']!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF010817), // Use your preferred background color
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          ),
                          child: Image.asset(
                            'assets/removeicon.png', // Replace with the path to your image
                            height: 24, // Set the height of the image
                            width: 24, // Set the width of the image
                          ),
                        ),

                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}