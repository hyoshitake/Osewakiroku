import 'package:flutter/material.dart';
import '../models/log.dart';
import '../services/google_sheets_service.dart';
import 'nursing_timer_dialog.dart';
import 'dart:collection';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<Log> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  // タイムスタンプごとにグループ化されたログを格納するマップ（時刻単位）
  SplayTreeMap<DateTime, List<Log>> _groupedLogs =
      SplayTreeMap<DateTime, List<Log>>((a, b) => b.compareTo(a));
  ScrollController _scrollController = ScrollController();
  int _displayedHours = 48; // 表示する時間数（初期は2日）

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // スクロールリスナー（インフィニティスクロール用）
  void _scrollListener() {
    // スクロール位置が80%に達したら追加読み込みを開始
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore) {
      _loadMoreLogs();
    }
  }

  // 追加のログを読み込む（過去のデータ）
  Future<void> _loadMoreLogs() async {
    setState(() {
      _isLoadingMore = true;
    });

    // 表示時間を12時間延長
    _displayedHours += 12;
    _groupLogs(_logs);

    // 少し待機してからローディングを終了（データを再グループ化する時間）
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoadingMore = false;
    });
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

    // 現在の時刻から過去に向かって指定時間分の枠を作成
    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);

    // 現在の時刻から過去に向かって時間枠を作成
    for (int i = 0; i < _displayedHours; i++) {
      final hourSlot = currentHour.subtract(Duration(hours: i));
      _groupedLogs[hourSlot] = [];
    }

    // ログを適切な時間枠に振り分ける
    for (final log in logs) {
      final logDate = log.timestamp;
      final hourSlot =
          DateTime(logDate.year, logDate.month, logDate.day, logDate.hour);

      if (_groupedLogs.containsKey(hourSlot)) {
        _groupedLogs[hourSlot]!.add(log);
      }
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

  // 授乳タイマーダイアログを表示するメソッド
  Future<void> _showNursingTimer() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NursingTimerDialog(),
    );

    if (result != null) {
      // タイマーの結果を授乳ログとして記録
      final side = result['side'] as String;
      final duration = result['duration'] as int;
      final minutes = duration ~/ 60;
      final seconds = duration % 60;

      final newLog = Log(
        timestamp: DateTime.now(),
        logType: '授乳',
        message: '$side側 ${minutes}分${seconds}秒',
        data1: side,
        data2: duration.toString(),
      );

      // 即座にUIを更新
      setState(() {
        _logs.add(newLog);
        _groupLogs(_logs);
      });

      // バックグラウンドでGoogle Sheetsに保存
      _saveToGoogleSheetsInBackground(newLog);
    }
  }

  Future<void> _addLog(String logType) async {
    final newLog = Log(
      timestamp: DateTime.now(),
      logType: logType,
      message: '$logTypeが記録されました',
      data1: '',
      data2: '',
    );

    // 即座にUIを更新（ローディング状態にしない）
    setState(() {
      _logs.add(newLog);
      _groupLogs(_logs); // ログを再グループ化
    });

    // バックグラウンドでGoogle Sheetsにデータを送信
    _saveToGoogleSheetsInBackground(newLog);
  }

  // バックグラウンドでGoogle Sheetsに保存するメソッド
  Future<void> _saveToGoogleSheetsInBackground(Log log) async {
    try {
      final success = await GoogleSheetsService.instance.addLog(log);

      if (!success) {
        // エラーの場合のみユーザーに通知（UIはブロックしない）
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sheetsへの保存に失敗しました'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // エラーの場合のみユーザーに通知（UIはブロックしない）
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 表示用のアイテムリストを生成するメソッド（日付区切り線を含む）
  List<Map<String, dynamic>> _getDisplayItems() {
    List<Map<String, dynamic>> displayItems = [];
    String? currentDate;

    for (final hourSlot in _groupedLogs.keys) {
      final dateString = '${hourSlot.year}年${hourSlot.month}月${hourSlot.day}日';

      // 日付が変わった場合は区切り線を追加
      if (currentDate != dateString) {
        displayItems.add({
          'type': 'date',
          'date': dateString,
        });
        currentDate = dateString;
      }

      // 時間行を追加
      displayItems.add({
        'type': 'hour',
        'hourSlot': hourSlot,
        'logs': _groupedLogs[hourSlot] ?? [],
      });
    }

    return displayItems;
  }

  // コンパクトなログアイコンウィジェットを構築するメソッド
  Widget _buildCompactLogIcon(Log log) {
    return GestureDetector(
      onTap: () => _showLogDetails(log),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _getLogTypeColor(log.logType),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getLogTypeIcon(log.logType),
          size: 16,
          color: Colors.black54,
        ),
      ),
    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNursingTimer,
        backgroundColor: Colors.pink.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        label: const Text(
          '授乳タイマー',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        icon: const Icon(
          Icons.timer,
          color: Colors.black87,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                              controller: _scrollController,
                              itemCount: _getDisplayItems().length +
                                  (_isLoadingMore ? 1 : 1), // 「さらに読み込む」用の追加項目
                              itemBuilder: (context, index) {
                                final displayItems = _getDisplayItems();

                                // 最後の項目は「さらに読み込む」またはローディング表示
                                if (index == displayItems.length) {
                                  return _isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: GestureDetector(
                                              onTap: () => _loadMoreLogs(),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12.0,
                                                        horizontal: 24.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                      color: Colors.grey[300]!),
                                                ),
                                                child: Text(
                                                  'さらに読み込む',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                }

                                final item = displayItems[index];

                                // 日付区切り線の表示
                                if (item['type'] == 'date') {
                                  return Column(
                                    children: [
                                      const Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                        height: 20,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          item['date'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // 時間行の表示
                                final hourSlot = item['hourSlot'] as DateTime;
                                final logsInHour = item['logs'] as List<Log>;
                                final timeFormat =
                                    hourSlot.hour.toString().padLeft(2, '0');

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // 左側に時間（HH）のみ表示
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          timeFormat,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // その時間帯のログアイコンを横に並べて表示
                                      Expanded(
                                        child: logsInHour.isEmpty
                                            ? const Text('記録なし',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12))
                                            : Wrap(
                                                spacing: 6.0,
                                                runSpacing: 4.0,
                                                children: logsInHour
                                                    .map((log) =>
                                                        _buildCompactLogIcon(
                                                            log))
                                                    .toList(),
                                              ),
                                      ),
                                    ],
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
