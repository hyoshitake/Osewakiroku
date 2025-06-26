import 'package:flutter/material.dart';
import '../models/log.dart';
import '../services/google_sheets_service.dart';
import 'dart:collection';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<Log> _logs = [];
  bool _isLoading = true;
  String _errorMessage = '';
  // 1時間ごとにグループ化されたログを格納するマップ
  SplayTreeMap<DateTime, List<Log>> _groupedLogs = SplayTreeMap<DateTime, List<Log>>((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  // Google Sheetsからログデータを読み込む
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Google Sheetsサービスからログを取得
      final logs = await GoogleSheetsService.instance.getLogs();

      setState(() {
        _logs = logs;
        _groupLogs(logs);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ログの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  // ログを1時間ごとにグループ化するメソッド
  void _groupLogs(List<Log> logs) {
    _groupedLogs.clear();

    // 現在の日付から24時間分の枠を作成
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 24時間分の空の時間枠を作成
    for (int i = 0; i < 24; i++) {
      final hourSlot = today.add(Duration(hours: i));
      _groupedLogs[hourSlot] = [];
    }

    // ログを適切な時間枠に振り分ける
    for (final log in logs) {
      final logDate = log.timestamp;
      final hourSlot = DateTime(logDate.year, logDate.month, logDate.day, logDate.hour);

      if (!_groupedLogs.containsKey(hourSlot)) {
        _groupedLogs[hourSlot] = [];
      }
      _groupedLogs[hourSlot]!.add(log);
    }
  }

  // ログの種類に応じたアイコンを返すメソッド
  IconData _getLogTypeIcon(String logType) {
    switch (logType) {
      case 'うんち':
        return Icons.pets;
      case 'おしっこ':
        return Icons.water_drop;
      case '授乳':
        return Icons.pregnant_woman;
      case 'ミルク':
        return Icons.baby_changing_station;
      default:
        return Icons.note;
    }
  }

  // ログの種類に応じた色を返すメソッド
  Color _getLogTypeColor(String logType) {
    switch (logType) {
      case 'うんち':
        return Colors.brown.shade200;
      case 'おしっこ':
        return Colors.yellow.shade200;
      case '授乳':
        return Colors.pink.shade200;
      case 'ミルク':
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  // ログボタンのウィジェットを構築するヘルパーメソッド
  Widget _buildLogButton(String logType, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () => _addLog(logType),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(60, 60), // 正方形のサイズ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // 角丸
          ),
          padding: const EdgeInsets.all(0),
        ),
        child: Icon(
          icon,
          size: 30,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ログのアイコンウィジェットを構築するメソッド
  Widget _buildLogIcon(Log log) {
    return GestureDetector(
      onTap: () => _showLogDetails(log),
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getLogTypeColor(log.logType),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getLogTypeIcon(log.logType),
          size: 24,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ログ詳細ダイアログを表示するメソッド
  void _showLogDetails(Log log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログ詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('時刻: ${log.timestamp.toLocal()}'),
            Text('種類: ${log.logType}'),
            Text('メッセージ: ${log.message}'),
            if (log.data1.isNotEmpty) Text('データ1: ${log.data1}'),
            if (log.data2.isNotEmpty) Text('データ2: ${log.data2}'),
            if (log.data3.isNotEmpty) Text('データ3: ${log.data3}'),
            if (log.data4.isNotEmpty) Text('データ4: ${log.data4}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _addLog(String logType) async {
    setState(() {
      _isLoading = true;
    });

    final newLog = Log(
      timestamp: DateTime.now(),
      logType: logType,
      message: '$logTypeが記録されました',
      data1: '',
      data2: '',
    );

    try {
      // Google Sheetsにログを追加
      final success = await GoogleSheetsService.instance.addLog(newLog);

      if (success) {
        // ログをローカルにも追加してUI更新
        setState(() {
          _logs.add(newLog);
          _groupLogs(_logs); // ログを再グループ化
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Google Sheetsへの書き込みに失敗しました';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ画面'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'ログを再読み込み',
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.shade100,
                        width: double.infinity,
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Expanded(
                      child: _groupedLogs.isEmpty
                          ? const Center(child: Text('ログはまだありません'))
                          : ListView.builder(
                              itemCount: _groupedLogs.length,
                              itemBuilder: (context, index) {
                                final hourSlot = _groupedLogs.keys.elementAt(index);
                                final logsInHour = _groupedLogs[hourSlot] ?? [];

                                // 時間帯の表示フォーマット
                                final timeFormat = '${hourSlot.hour.toString().padLeft(2, '0')}:00';

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 時間帯の表示
                                        Text(
                                          timeFormat,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // その時間帯のログアイコンを横に並べて表示
                                        logsInHour.isEmpty
                                            ? const Text('記録なし', style: TextStyle(color: Colors.grey))
                                            : Wrap(
                                                spacing: 8.0,
                                                runSpacing: 8.0,
                                                children: logsInHour.map((log) => _buildLogIcon(log)).toList(),
                                              ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLogButton(
                            'うんち', Icons.pets, Colors.brown.shade200),
                        _buildLogButton(
                            'おしっこ', Icons.water_drop, Colors.yellow.shade200),
                        _buildLogButton(
                            '授乳', Icons.pregnant_woman, Colors.pink.shade200),
                        _buildLogButton('ミルク', Icons.baby_changing_station,
                            Colors.blue.shade200),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
