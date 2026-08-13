import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../features/transactions/data/transaction_database.dart';

class BackupService {
  static const String defaultFileName = 'fontakip_backup.json';

  static const List<String> _tables = [
    'transactions',
    'stock_transactions',
    'debts',
    'favorites',
    'stock_favorites',
  ];

  Future<Map<String, dynamic>> createBackupPayload() async {
    final db = await TransactionDatabase.instance.database;
    final prefs = await SharedPreferences.getInstance();

    final dbData = <String, dynamic>{};
    for (final table in _tables) {
      dbData[table] = await db.query(table);
    }

    final sharedPrefsData = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      sharedPrefsData[key] = prefs.get(key);
    }

    return <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'database': dbData,
      'sharedPreferences': sharedPrefsData,
    };
  }

  Future<String> createBackupJson({bool pretty = false}) async {
    final payload = await createBackupPayload();
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(payload);
  }

  Future<String?> exportBackup() async {
    final tempDir = await getTemporaryDirectory();
    final selectedPath = '${tempDir.path}/$defaultFileName';
    final jsonContent = await createBackupJson(pretty: true);
    final file = File(selectedPath);

    await file.writeAsString(jsonContent);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'FontTakip Yedeği',
    );

    return selectedPath;
  }

  Future<bool> importBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Yedek dosyasını seç',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return false;
    }

    final selectedPath = picked.files.single.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      return false;
    }

    final file = File(selectedPath);
    final raw = await file.readAsString();
    await importBackupFromJson(raw);
    return true;
  }

  Future<void> importBackupFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Geçersiz yedek dosyası');
    }

    await importBackupPayload(decoded);
  }

  Future<void> importBackupPayload(Map<String, dynamic> decoded) async {
    final databaseData = decoded['database'];
    final prefsData = decoded['sharedPreferences'];
    if (databaseData is! Map<String, dynamic> || prefsData is! Map<String, dynamic>) {
      throw const FormatException('Yedek içeriği hatalı');
    }

    final db = await TransactionDatabase.instance.database;
    await _restoreDatabase(db, databaseData);
    await _restoreSharedPreferences(prefsData);
  }

  Future<void> resetAllUserData() async {
    final db = await TransactionDatabase.instance.database;
    await _clearDatabaseTables(db);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _restoreDatabase(
    Database db,
    Map<String, dynamic> databaseData,
  ) async {
    await db.transaction((txn) async {
      await _clearTablesInTransaction(txn);

      for (final table in _tables) {
        final rows = databaseData[table];
        if (rows is! List) {
          continue;
        }

        for (final row in rows) {
          if (row is! Map) {
            continue;
          }
          await txn.insert(
            table,
            _normalizeMap(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> _clearDatabaseTables(Database db) async {
    await db.transaction((txn) async {
      await _clearTablesInTransaction(txn);
    });
  }

  Future<void> _clearTablesInTransaction(Transaction txn) async {
    for (final table in _tables) {
      await txn.delete(table);
    }
  }

  Future<void> _restoreSharedPreferences(Map<String, dynamic> prefsData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    for (final entry in prefsData.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        final list = value.map((item) => item.toString()).toList();
        await prefs.setStringList(key, list);
      }
    }
  }

  Map<String, Object?> _normalizeMap(Map row) {
    final normalized = <String, Object?>{};
    for (final entry in row.entries) {
      normalized[entry.key.toString()] = entry.value;
    }
    return normalized;
  }
}
