import 'package:flutter/material.dart';
import '../models/log.dart';
import '../services/google_sheets_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<Log> _logs = [];
  bool _isLoading = true;
  String _errorMessage = '';

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ログの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  // 新しいログをGoogle Sheetsに追加
  Future<void> _addLog() async {
    setState(() {
      _isLoading = true;
    });

    final newLog = Log(
      timestamp: DateTime.now(),
      logType: 'INFO',
      message: '新しいログエントリが追加されました',
      data1: 'サンプルデータ1',
      data2: 'サンプルデータ2',
    );

    try {
      // Google Sheetsにログを追加
      final success = await GoogleSheetsService.instance.addLog(newLog);

      if (success) {
        // ログをローカルにも追加してUI更新
        setState(() {
          _logs.add(newLog);
          _isLoading = false;
        });

        // または、すべてのログを再読み込み
        await _loadLogs();
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
          : Column(
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _addLog,
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
                Expanded(
                  child: _logs.isEmpty
                      ? const Center(child: Text('ログはまだありません'))
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log =
                                _logs[_logs.length - 1 - index]; // 新しいログを上に表示
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              child: ListTile(
                                title: Text(
                                  log.message,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${log.timestamp.toLocal().toString()} - ${log.logType}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                onTap: () {
                                  // タップしたときの処理（詳細表示など）
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('ログ詳細'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '時刻: ${log.timestamp.toLocal()}'),
                                          Text('種類: ${log.logType}'),
                                          Text('メッセージ: ${log.message}'),
                                          if (log.data1.isNotEmpty)
                                            Text('データ1: ${log.data1}'),
                                          if (log.data2.isNotEmpty)
                                            Text('データ2: ${log.data2}'),
                                          if (log.data3.isNotEmpty)
                                            Text('データ3: ${log.data3}'),
                                          if (log.data4.isNotEmpty)
                                            Text('データ4: ${log.data4}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('閉じる'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
