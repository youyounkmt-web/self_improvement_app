import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("設定")),
      body: const Center(
        child: Text(
          "ここに設定画面の内容を表示します",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
