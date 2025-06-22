import 'package:flutter/material.dart';
import '../models/log.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final List<Log> _logs = [];

  void _addLog() {
    final newLog = Log(
      timestamp: DateTime.now(),
      logType: 'INFO',
      message: '新しいログエントリが追加されました',
      data1: 'サンプルデータ1',
      data2: 'サンプルデータ2',
    );

    setState(() {
      _logs.add(newLog);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ画面'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
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
                      final log = _logs[_logs.length - 1 - index]; // 新しいログを上に表示
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            log.message,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('時刻: ${log.timestamp.toLocal()}'),
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
