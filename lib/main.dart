import 'package:flutter/material.dart';
import 'home_page.dart';
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
  const MyApp({super.key, required this.isSurveyDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'スケジュールアプリ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StartPage(isSurveyDone: isSurveyDone), // ✅ StartPageに渡す！
      debugShowCheckedModeBanner: false,
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
                if (isSurveyDone) {
                  // ✅ すでにアンケート済みなら直接カレンダー
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
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

// -------------------ホーム画面 ------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _points = 120; // 仮のポイント
  int _loginStreak = 5; // 連続ログイン日数（仮）

  Color _getColorForPoints(int points) {
    if (points >= 200) return Colors.amber; // 金色
    if (points >= 100) return Colors.green;
    if (points >= 50) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ホーム"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 上部：ログイン日数とポイント
            Column(
              children: [
                Text("連続ログイン日数: $_loginStreak日",
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 8),
                Text("ポイント: $_points pt", style: const TextStyle(fontSize: 20)),
              ],
            ),

            // 中央：ポイントに応じた色の変化
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getColorForPoints(_points),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  "あなたのステータス",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 下部：ボタン2つ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CalendarPage()),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("カレンダーへ"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("設定へ"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------ 設定画面 ------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: const Center(
        child: Text("ここに設定項目を追加予定"),
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
        MaterialPageRoute(builder: (context) => const HomePage()),
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

  Future<void> _resetEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('events'); // 保存されている予定を削除
    setState(() {
      _events.clear(); // メモリ上の予定も削除
    });
  }

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
    _loadEvents().then((_) {
      _autoSchedule(); // ← ロード完了後に呼ぶ
    });
  }

// ------------------ 自動スケジューリングロジック ------------------

  Future<void> _autoSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final weakness = prefs.getString('weakness'); // アンケート結果を取得

    // 既存イベントがあればスキップ（初回のみ生成）
    final existingEvents = prefs.getString('events');
    if (existingEvents != null && existingEvents.isNotEmpty) return;

    // カテゴリごとの割当回数（2週間あたりに変更）
    final Map<String, int> baseSchedule = {
      '筋トレ': 2,
      '服を買う': 2,
      '勉強': 2,
      'その他': 2,
    };

    // 弱点に応じて強化カテゴリを週2-3回 → 2週間で4〜6回に増やす
    if (weakness == "ファッション") {
      baseSchedule['服を買う'] = 6;
    } else if (weakness == "恋愛知識") {
      baseSchedule['勉強'] = 6;
    } else if (weakness == "清潔感") {
      baseSchedule['筋トレ'] = 6;
    }

    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final random = Random();

    // 今後2週間分を自動生成
    final totalDays = 14;
    List<DateTime> allDays = List.generate(
      totalDays,
      (i) => startOfWeek.add(Duration(days: i)),
    );
    allDays.shuffle(random);

    // 割り当てるカテゴリを全部まとめてリスト化
    List<String> scheduleList = [];
    baseSchedule.forEach((category, count) {
      scheduleList.addAll(List.filled(count, category));
    });

    // カテゴリのリストもシャッフルして分散
    scheduleList.shuffle(random);

    // 1日1件制約を守りながらスケジュールを割り当てる
    int dayIndex = 0;
    for (String category in scheduleList) {
      // 空き日を探す
      while (dayIndex < allDays.length) {
        final day = allDays[dayIndex];
        dayIndex++;

        // 既に予定が入っていない日だけに追加
        if (_getEventsForDay(day).isEmpty) {
          print("🗓 ${day.toString().split(' ')[0]} に $category を追加");
          _addEvent("$category の予定", category, day);
          break;
        }
      }

      // 空き日が尽きたら終了
      if (dayIndex >= allDays.length) break;
    }

    await _saveEvents();
    setState(() {});
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
    int streak = prefs.getInt("streak") ?? 1;

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month}-${yesterday.day}";

    if (_lastLoginDate != todayStr) {
      // 連続ログイン判定
      if (_lastLoginDate == yesterdayStr) {
        streak++;
      } else {
        streak = 1; // 途切れた
      }

      const dailyBonus = 10;
      _points += dailyBonus;
      _lastLoginDate = todayStr;

      await prefs.setInt("points", _points);
      await prefs.setString("lastLoginDate", todayStr);
      await prefs.setInt("streak", streak);

      setState(() {});
    }
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
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _addEvent(String name, String category, DateTime day) {
    final date = DateTime(day.year, day.month, day.day); // ← dayを使う
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
            icon: const Icon(Icons.refresh), // 🔄 リセットアイコン
            onPressed: _resetEvents, // 押すと予定をリセット
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
          ),
        ],
      ),
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
                          _addEvent(inputText, selectedCategory, _selectedDay);
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
