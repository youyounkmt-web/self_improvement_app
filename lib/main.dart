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
      backgroundColor: Colors.deepPurple.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today,
                size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              '自分磨き（仮）',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('START',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
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

  // カテゴリ（SharedPreferences保存対象）
  List<Map<String, dynamic>> _categories = [
    {"name": "筋トレ", "color": Colors.red.value},
    {"name": "服を買う", "color": Colors.blue.value},
    {"name": "勉強", "color": Colors.green.value},
    {"name": "その他", "color": Colors.grey.value},
  ];

  final Map<DateTime, List<Map<String, String>>> _events = {};

  // ログインボーナス
  int _points = 0;
  String? _lastLoginDate;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadLoginBonus();
    _loadEvents();
  }

  // ------------------ カテゴリ処理 ------------------
  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? catJson = prefs.getString('categories');
    if (catJson != null) {
      final List decoded = json.decode(catJson);
      _categories = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      setState(() {});
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categories', json.encode(_categories));
  }

  // ------------------ ログインボーナス ------------------
  Future<void> _loadLoginBonus() async {
    final prefs = await SharedPreferences.getInstance();
    _points = prefs.getInt("points") ?? 0;
    _lastLoginDate = prefs.getString("lastLoginDate");

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    if (_lastLoginDate != todayStr) {
      // 1日1回 +10pt
      const dailyBonus = 10;
      _points += dailyBonus;
      _lastLoginDate = todayStr;

      await prefs.setInt("points", _points);
      await prefs.setString("lastLoginDate", todayStr);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("ログインボーナス"),
            content:
                Text("今日もログインありがとう！\n+${dailyBonus}pt 獲得 🎁\n合計：$_points pt"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"))
            ],
          ),
        );
      });
    }
    setState(() {});
  }

  // ------------------ イベント処理 ------------------
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
          _events[date] = List<Map<String, String>>.from(
              value.map((e) => Map<String, String>.from(e)));
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

  // カテゴリ名から色を取得
  Color _getCategoryColor(String category) {
    final found = _categories.firstWhere((c) => c["name"] == category,
        orElse: () => {"color": Colors.grey.value});
    return Color(found["color"]);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("自分磨きカレンダー(仮)"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("ポイント: $_points pt"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryPage(
                    categories: _categories,
                    onSave: (updated) {
                      setState(() {
                        _categories = updated;
                        _saveCategories();
                      });
                    },
                  ),
                ),
              );
            },
          )
        ],
      ),
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
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getCategoryColor(category),
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
                        backgroundColor: _getCategoryColor(category),
                        radius: 8),
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
          String selectedCategory = _categories.first["name"];

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
                            .map<DropdownMenuItem<String>>(
                                (c) => DropdownMenuItem<String>(
                                      value: c["name"],
                                      child: Text(c["name"]),
                                    ))
                            .toList(),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル')),
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

// ------------------ カテゴリ管理画面 ------------------
class CategoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Function(List<Map<String, dynamic>>) onSave;

  const CategoryPage(
      {super.key, required this.categories, required this.onSave});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late List<Map<String, dynamic>> _localCategories;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
  }

  void _addCategory() {
    String name = '';
    Color color = Colors.grey;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("新しいカテゴリ"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "カテゴリ名"),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.purple,
                    Colors.orange,
                    Colors.pink,
                    Colors.teal,
                    Colors.grey,
                  ].map((c) {
                    return GestureDetector(
                      onTap: () => setStateDialog(() => color = c),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color:
                                color == c ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("キャンセル")),
              TextButton(
                onPressed: () {
                  if (name.isNotEmpty) {
                    setState(() {
                      _localCategories
                          .add({"name": name, "color": color.value});
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text("追加"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeCategory(int index) {
    setState(() => _localCategories.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("カテゴリ管理"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave(_localCategories);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _localCategories.length,
        itemBuilder: (context, index) {
          final category = _localCategories[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: Color(category["color"])),
            title: Text(category["name"]),
            trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeCategory(index)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _addCategory,
      ),
    );
  }
}
