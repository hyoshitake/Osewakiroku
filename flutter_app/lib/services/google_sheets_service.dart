import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log.dart';
import '../config/credentials.dart';

class GoogleSheetsService {
  static const _sheetIdKey = 'google_sheet_id';
  static GoogleSheetsService? _instance;
  String? _sheetId;
  Spreadsheet? _spreadsheet;
  Worksheet? _worksheet;
  bool _isInitialized = false;

  GoogleSheetsService._(); // プライベートコンストラクタ

  static GoogleSheetsService get instance {
    _instance ??= GoogleSheetsService._();
    return _instance!;
  }

  // 匿名での認証（公開シートアクセス）
  Future<bool> initialize(String sheetId) async {
    if (_isInitialized && _sheetId == sheetId) {
      return true;
    }

    try {
      // シートIDを保存
      _sheetId = sheetId;

      // シートIDを永続化
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sheetIdKey, sheetId);

      // 外部ファイルから認証情報を取得
      final gsheets = GSheets(googleSheetsCredentials);

      // スプレッドシートへの接続
      _spreadsheet = await gsheets.spreadsheet(sheetId);

      // 最初のワークシートを取得または作成
      _worksheet = await _getOrCreateWorksheet(_spreadsheet!, 'Logs');

      // ヘッダー行がなければ追加
      await _ensureHeaderRow();

      _isInitialized = true;

      return true;
    } catch (e) {
      debugPrint('Google Sheets初期化エラー: $e');
      _isInitialized = false;
      return false;
    }
  }

  // 保存されたシートIDを取得
  Future<String?> getSavedSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sheetIdKey);
  }

  // ワークシートを取得または作成
  Future<Worksheet> _getOrCreateWorksheet(
      Spreadsheet spreadsheet, String title) async {
    var worksheet = spreadsheet.worksheetByTitle(title);
    if (worksheet == null) {
      // ワークシートが存在しない場合は新規作成
      worksheet = await spreadsheet.addWorksheet(title);
    }
    return worksheet!;
  }

  // ヘッダー行を確保
  Future<void> _ensureHeaderRow() async {
    if (_worksheet == null) return;

    // ヘッダー行が空かどうか確認
    final firstRow = await _worksheet!.values.row(1);
    if (firstRow.isEmpty) {
      // ヘッダー行を追加
      await _worksheet!.values.insertRow(1, [
        'timestamp',
        'logType',
        'message',
        'data1',
        'data2',
        'data3',
        'data4'
      ]);
    }
  }

  // ログを追加
  Future<bool> addLog(Log log) async {
    if (!_isInitialized || _worksheet == null) {
      debugPrint('Google Sheetsが初期化されていません');
      return false;
    }

    try {
      // ログデータを行として追加
      await _worksheet!.values.appendRow([
        log.timestamp.toIso8601String(),
        log.logType,
        log.message,
        log.data1,
        log.data2,
        log.data3,
        log.data4,
      ]);

      return true;
    } catch (e) {
      debugPrint('ログ追加エラー: $e');
      return false;
    }
  }

  // すべてのログを取得
  Future<List<Log>> getLogs() async {
    if (!_isInitialized || _worksheet == null) {
      debugPrint('Google Sheetsが初期化されていません');
      return [];
    }

    try {
      // すべての行を取得（ヘッダー行を除く）
      final rows = await _worksheet!.values.allRows();
      if (rows.isEmpty) {
        return [];
      }

      // ヘッダー行をスキップ
      final dataRows = rows.skip(1).toList();

      // 各行をLogオブジェクトに変換
      return dataRows.map((row) {
        // エポック日付（小数点付の数値）をDateTimeに変換する処理
        DateTime timestamp;
        debugPrint('row[0]: ${row[0]}');
        try {
          // まず標準的なISO8601形式での解析を試みる
          timestamp = DateTime.parse(row[0]);
        } catch (e) {
          try {
            // Google Sheetsの日付シリアル値の場合（1900年1月1日からの経過日数）
            final serialValue = double.parse(row[0]);
            debugPrint('serialValue: $serialValue');

            // Google Sheetsの日付シリアル値を日時に変換
            // Google Sheetsの基準日: 1899年12月30日（Excelとの互換性のため）
            final baseDate = DateTime(1899, 12, 30);

            // シリアル値の整数部分が日数、小数部分が時間
            final days = serialValue.floor();
            final timeFraction = serialValue - days;

            // 日数を加算
            var resultDate = baseDate.add(Duration(days: days));

            // 時間部分を加算（24時間 = 1.0）
            final totalSeconds = (timeFraction * 24 * 60 * 60).round();
            resultDate = resultDate.add(Duration(seconds: totalSeconds));

            timestamp = resultDate;
            debugPrint('timestamp: $timestamp');
          } catch (e) {
            // どちらの形式でも解析できない場合は現在時刻を使用
            debugPrint('タイムスタンプの解析エラー: ${row[0]}');
            timestamp = DateTime.now();
          }
        }

        return Log(
          timestamp: timestamp,
          logType: row[1],
          message: row[2],
          data1: row.length > 3 ? row[3] : '',
          data2: row.length > 4 ? row[4] : '',
          data3: row.length > 5 ? row[5] : '',
          data4: row.length > 6 ? row[6] : '',
        );
      }).toList();
    } catch (e) {
      debugPrint('ログ取得エラー: $e');
      return [];
    }
  }

  // GoogleシートのURLを取得
  String getSheetUrl() {
    if (_sheetId == null) return '';
    return 'https://docs.google.com/spreadsheets/d/$_sheetId';
  }

  // 初期化状態を確認
  bool get isInitialized => _isInitialized;
}
