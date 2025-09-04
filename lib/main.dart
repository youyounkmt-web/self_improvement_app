import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自分磨き（仮）HARIBO Chamallows Soft kiss仕様',
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
      backgroundColor: Colors.deepPurple.shade100,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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

  final List<String> _categories = ['筋トレ', '服を買う', '勉強', 'その他'];

  // カテゴリーごとの色
  final Map<String, Color> _categoryColors = {
    '筋トレ': Colors.red,
    '服を買う': Colors.blue,
    '勉強': Colors.green,
    'その他': Colors.grey,
  };

  final Map<DateTime, List<Map<String, String>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  String _dateToString(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  DateTime _stringToDate(String dateString) {
    final parts = dateString.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final decodedData = json.decode(eventsJson);
      _events.clear();

      decodedData.forEach((key, value) {
        final date = _stringToDate(key);
        if (value is List) {
          if (value.isNotEmpty && value.first is String) {
            _events[date] = (value as List)
                .map((e) => {'name': e as String, 'category': 'その他'})
                .toList();
          } else if (value.isNotEmpty && value.first is Map) {
            _events[date] = List<Map<String, String>>.from(
                (value as List).map((e) => Map<String, String>.from(e)));
          } else {
            _events[date] = [];
          }
        }
      });

      setState(() {});
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> serializableMap =
        _events.map((key, value) => MapEntry(_dateToString(key), value));
    await prefs.setString('events', json.encode(serializableMap));
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent(String name, String category) {
    final date =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    if (_events[date] == null) _events[date] = [];
    _events[date]!.add({'name': name, 'category': category});
    _saveEvents();
    setState(() {});
  }

  void _removeEvent(Map<String, String> event) {
    final date =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _events[date]?.remove(event);
    _saveEvents();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('チョコマシュカレンダー')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _getEventsForDay(day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((event) {
                    final category =
                        (event as Map<String, String>)['category'] ?? 'その他';
                    final color = _categoryColors[category] ?? Colors.grey;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay).map((event) {
                final category = event['category'] ?? 'その他';
                final color = _categoryColors[category] ?? Colors.grey;
                final displayText = event['name'] ?? '';

                return Dismissible(
                  key: Key(displayText + category),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _removeEvent(event),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      radius: 8,
                    ),
                    title: Text(displayText),
                    subtitle: Text(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          String inputText = '';
          String selectedCategory = _categories[0];

          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setStateDialog) => AlertDialog(
                  title: const Text('予定を追加'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onChanged: (value) => inputText = value,
                        decoration:
                            const InputDecoration(hintText: '予定を入力してください'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<String>(
                        value: selectedCategory,
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedCategory = value;
                            });
                          }
                        },
                        items: _categories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (inputText.isNotEmpty) {
                          _addEvent(inputText, selectedCategory);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('追加'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
