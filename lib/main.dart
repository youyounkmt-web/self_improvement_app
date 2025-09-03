import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'dart:convert'; // Add this import for JSON encoding/decoding

//takeが編集したよ
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自分磨き（仮）',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const StartPage(),
    );
  }
}

// ------------------ スタート画面 ------------------
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade100, // 背景色
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              '自分磨き（仮）',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                'START',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ カレンダー画面 ------------------
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // 日付ごとの予定を保存する Map
  final Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents(); // Load events when the widget initializes
  }

  // A helper function to create a simplified key for DateTime objects
  String _dateToString(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  // A helper function to parse the string key back to a DateTime object
  DateTime _stringToDate(String dateString) {
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Function to load events from shared_preferences
  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final Map<String, dynamic> decodedData = json.decode(eventsJson);
      decodedData.forEach((key, value) {
        _events[_stringToDate(key)] = List<String>.from(value);
      });
      setState(() {});
    }
  }

  // Function to save events to shared_preferences
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert DateTime keys to String keys for JSON serialization
    final Map<String, dynamic> serializableMap = _events.map(
      (key, value) => MapEntry(_dateToString(key), value),
    );
    await prefs.setString('events', json.encode(serializableMap));
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent(String event) {
    final date = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    if (_events[date] == null) {
      _events[date] = [];
    }
    _events[date]!.add(event);
    _saveEvents(); // Save events after adding
    setState(() {});
  }

  void _removeEvent(String event) {
    final date = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    _events[date]?.remove(event);
    _saveEvents(); // Save events after removing
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダーアプリ')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay)
                  .map(
                    (event) => Dismissible(
                      key: Key(event),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _removeEvent(event);
                      },
                      child: ListTile(title: Text(event)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String inputText = '';
              return AlertDialog(
                title: const Text('予定を追加'),
                content: TextField(
                  onChanged: (value) {
                    inputText = value;
                  },
                  decoration: const InputDecoration(hintText: '予定を入力してください'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (inputText.isNotEmpty) {
                        _addEvent(inputText);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('追加'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
