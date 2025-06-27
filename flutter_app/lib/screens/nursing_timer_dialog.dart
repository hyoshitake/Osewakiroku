import 'package:flutter/material.dart';
import 'dart:async';

class NursingTimerDialog extends StatefulWidget {
  const NursingTimerDialog({super.key});

  @override
  State<NursingTimerDialog> createState() => _NursingTimerDialogState();
}

class _NursingTimerDialogState extends State<NursingTimerDialog> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = true; // 開始時点でタイマーが動いている
  String _currentSide = '左'; // 左側または右側

  @override
  void initState() {
    super.initState();
    // ダイアログ開始時に即座にタイマーを開始
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime() {
    final minutes = _seconds ~/ 60;
    final remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 左胸と右胸のトグルスイッチ
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentSide = '左';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentSide == '左'
                            ? Colors.pink.shade200
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '左胸',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: _currentSide == '左'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentSide = '右';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _currentSide == '右'
                            ? Colors.pink.shade200
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '右胸',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: _currentSide == '右'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // タイマー表示
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _formatTime(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 一時停止/再開ボタン（アイコン付き）
            ElevatedButton(
              onPressed: _isRunning ? _pauseTimer : _resumeTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isRunning ? Colors.orange.shade200 : Colors.green.shade200,
                minimumSize: const Size(120, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRunning ? '一時停止' : '再開',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 閉じるボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // タイマーの記録を保存して閉じる
                    Navigator.of(context).pop({
                      'side': _currentSide,
                      'duration': _seconds,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade200,
                  ),
                  child: const Text(
                    '記録して閉じる',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
