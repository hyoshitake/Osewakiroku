class Log {
  final DateTime timestamp;
  final String logType;
  final String data1;
  final String data2;
  final String data3;
  final String data4;
  final String message;

  Log({
    required this.timestamp,
    required this.logType,
    this.data1 = '',
    this.data2 = '',
    this.data3 = '',
    this.data4 = '',
    required this.message,
  });

  @override
  String toString() {
    return 'Log(timestamp: $timestamp, logType: $logType, message: $message)';
  }

  // JSONデータへの変換メソッド
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'logType': logType,
      'data1': data1,
      'data2': data2,
      'data3': data3,
      'data4': data4,
      'message': message,
    };
  }

  // JSONデータからLogオブジェクトを作成するファクトリメソッド
  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      timestamp: DateTime.parse(json['timestamp']),
      logType: json['logType'],
      data1: json['data1'] ?? '',
      data2: json['data2'] ?? '',
      data3: json['data3'] ?? '',
      data4: json['data4'] ?? '',
      message: json['message'],
    );
  }
}
