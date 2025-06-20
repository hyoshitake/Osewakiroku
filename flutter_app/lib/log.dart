import 'package:flutter/material.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ画面'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // ボタンがタップされたときの処理
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink.shade100, // 薄いピンク色
            minimumSize: const Size(60, 60), // 正方形のサイズ
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // 角丸
            ),
          ),
          child: const Text(
            '+',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
