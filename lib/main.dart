import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // ✅ デバッグ中は毎回アンケートを表示する
  final bool isSurveyDone =
      kDebugMode ? false : (prefs.getBool('isSurveyDone') ?? false);

  runApp(MyApp(isSurveyDone: isSurveyDone));
}

class MyApp extends StatelessWidget {
  final bool isSurveyDone;
  const MyApp({Key? key, required this.isSurveyDone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '自分磨きアプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StartPage(isSurveyDone: isSurveyDone), // ✅ まずは必ずスタートから
    );
  }
}

// ------------------ スタート画面 ------------------
class StartPage extends StatelessWidget {
  final bool isSurveyDone;
  const StartPage({super.key, required this.isSurveyDone});

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
                if (isSurveyDone) {
                  // ✅ すでにアンケート済みなら直接カレンダー
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CalendarPage()),
                  );
                } else {
                  // ✅ 初回ならアンケートへ
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SurveyPage()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ アンケート画面 ------------------
class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  String? _selectedWeakness;

  final List<String> _options = [
    "清潔感",
    "ファッション",
    "コミュニケーション",
    "恋愛知識",
  ];

  Future<void> _finishSurvey() async {
    if (_selectedWeakness == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSurveyDone', true); // ✅ 完了したことを保存
    await prefs.setString('weakness', _selectedWeakness!);

    if (mounted) {
      // ✅ 完了後はカレンダーへ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CalendarPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("アンケート")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "今自分の中で一番自信がないものを選んでください：",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._options.map(
              (option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                // ignore: deprecated_member_use
                groupValue: _selectedWeakness,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  setState(() {
                    _selectedWeakness = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _selectedWeakness != null ? _finishSurvey : null,
                child: const Text("完了"),
              ),
            )
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
    _autoSchedule();
  }
// ------------------ 自動スケジューリングロジック ------------------

  Future<void> _autoSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final weakness = prefs.getString('weakness'); // アンケート結果を取得

    // 既存イベントがあればスキップ（初回のみ生成）
    final existingEvents = prefs.getString('events');
    if (existingEvents != null && existingEvents.isNotEmpty) return;

    // カテゴリごとの割当回数（1週間あたり）
    final Map<String, int> baseSchedule = {
      '筋トレ': 1,
      '服を買う': 1,
      '勉強': 1,
      'その他': 1,
    };

    // 弱点に応じて強化カテゴリを週2-3回に増やす
    if (weakness == "ファッション") {
      baseSchedule['服を買う'] = 3;
    } else if (weakness == "恋愛知識") {
      baseSchedule['勉強'] = 3;
    } else if (weakness == "清潔感") {
      baseSchedule['筋トレ'] = 3;
    }

    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final random = Random();

    // 今後4週間分を自動生成
    for (int week = 0; week < 4; week++) {
      final weekStart = startOfWeek.add(Duration(days: week * 7));

      // 1週間 = 7日分のスロットを用意してシャッフル
      List<DateTime> availableDays =
          List.generate(7, (i) => weekStart.add(Duration(days: i)));
      availableDays.shuffle(random);

      // 割り当てるカテゴリを全部まとめてリスト化
      List<String> scheduleList = [];
      baseSchedule.forEach((category, count) {
        scheduleList.addAll(List.filled(count, category));
      });

      // カテゴリのリストもシャッフルして分散
      scheduleList.shuffle(random);

      // 両方のリストを順番にマッチング
      for (int i = 0;
          i < scheduleList.length && i < availableDays.length;
          i++) {
        final category = scheduleList[i];
        final day = availableDays[i];

        if (_getEventsForDay(day).isEmpty) {
          _addEvent("$category の予定", category);
        }
      }
    }
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
            _events[date] = value
                .map((e) => {'name': e as String, 'category': 'その他'})
                .toList();
          } else if (value.isNotEmpty && value.first is Map) {
            _events[date] = List<Map<String, String>>.from(
                value.map((e) => Map<String, String>.from(e)));
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
            calendarFormat: CalendarFormat.twoWeeks,
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
                  key: ValueKey(displayText + category),
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
                        keyboardType: TextInputType.text, // 日本語入力に対応
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          inputText = value;
                        },
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
