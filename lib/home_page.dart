// lib/home_page.dart
import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _points = 0;
  int _streak = 1;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _points = prefs.getInt('points') ?? 0;
      _streak = prefs.getInt('streak') ?? 1;
    });
  }

  Color _getColorForPoints(int points) {
    if (points >= 200) return Colors.amber;
    if (points >= 100) return Colors.green;
    if (points >= 50) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('連続ログイン: $_streak 日',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Text('ポイント: $_points pt',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 中央：色が変わる円
            Expanded(
              child: Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColorForPoints(_points),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 8)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _points < 50
                          ? '初心者'
                          : _points < 100
                              ? '成長中'
                              : _points < 200
                                  ? '達人'
                                  : '王者',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            // 下部ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('カレンダー'),
                  onPressed: () {
                    // ここで CalendarPage を使っているため import は「使用中」になります
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CalendarPage()),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('設定'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
