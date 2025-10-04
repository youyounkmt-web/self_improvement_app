import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("カレンダー")),
      body: const Center(
        child: Text(
          "ここにカレンダー画面の内容を表示します",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
