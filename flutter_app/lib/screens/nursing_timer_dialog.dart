import 'package:flutter/material.dart';
import 'dart:async';

class NursingTimerDialog extends StatefulWidget {
  const NursingTimerDialog({Key? key}) : super(key: key);

  @override
  State<NursingTimerDialog> createState() => _NursingTimerDialogState();
}

class _NursingTimerDialogState extends State<NursingTimerDialog> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  String _currentSide = '左'; // 左側または右側

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

  void _stopTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  void _switchSide() {
    setState(() {
      _currentSide = _currentSide == '左' ? '右' : '左';
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
            const Text(
              '授乳タイマー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 現在の側表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '現在: $_currentSide側',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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

            // 側切り替えボタン
            ElevatedButton(
              onPressed: _switchSide,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade200,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '${_currentSide == '左' ? '右' : '左'}側に切り替え',
                style: const TextStyle(color: Colors.black87),
              ),
            ),

            const SizedBox(height: 16),

            // タイマー制御ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isRunning ? '停止' : '開始',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'リセット',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
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
