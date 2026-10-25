import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'notification_cache_store.dart';

/// Local SQLite cache for volcanoes, news, notifications, and sync timestamps.
class GunungLocalStore implements NotificationCacheStore {
  factory GunungLocalStore({DatabaseFactory? factory, String? databasePath}) =>
      GunungLocalStore._(factory, databasePath);

  GunungLocalStore._(this._factory, this._databasePath);

  static final GunungLocalStore instance = GunungLocalStore();

  final DatabaseFactory? _factory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get _db async {
    if (_database case final database?) return database;
    final path =
        _databasePath ?? '${await getDatabasesPath()}/ranah_offline.db';
    final database = await (_factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE gunung (
              id INTEGER PRIMARY KEY,
              nama TEXT,
              aktif INTEGER NOT NULL DEFAULT 1,
              tercantum INTEGER NOT NULL DEFAULT 1,
              payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE laporan_gunung (
              id INTEGER PRIMARY KEY,
              gunung_id INTEGER NOT NULL,
              waktu_publikasi TEXT,
              payload TEXT NOT NULL,
              FOREIGN KEY (gunung_id) REFERENCES gunung(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE INDEX laporan_gunung_parent_order
            ON laporan_gunung(gunung_id, waktu_publikasi DESC, id DESC)
          ''');
          await db.execute('''
            CREATE TABLE metadata (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await _createNewsTable(db);
          await _createNotificationsTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createNewsTable(db);
          if (oldVersion < 3) {
            await db.execute(
              'ALTER TABLE gunung ADD COLUMN tercantum INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (oldVersion < 4) await _createNotificationsTable(db);
        },
      ),
    );
    _database = database;
    return database;
  }

  Future<List<Map<String, dynamic>>> readGunung() async {
    final rows = await (await _db).query(
      'gunung',
      columns: ['payload'],
      where: 'tercantum = 1',
      orderBy: 'nama COLLATE NOCASE ASC',
    );
    return rows.map((row) => _decode(row['payload'] as String)).toList();
  }

  Future<void> saveGunung(
    List<Map<String, dynamic>> items, {
    required DateTime checkedAt,
  }) async {
    final db = await _db;
    await db.transaction((transaction) async {
      // This flag tracks listing membership only. It is not an active/inactive
      // volcano classification, and cached detail rows remain untouched.
      if (items.isNotEmpty) {
        await transaction.update('gunung', {'tercantum': 0});
      }
      for (final item in items) {
        final id = _requiredId(item['id'], 'gunung');
        final payload = jsonEncode(item);
        await transaction.insert('gunung', {
          'id': id,
          'nama': item['nama']?.toString(),
          'aktif': 1,
          'tercantum': 1,
          'payload': payload,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await transaction.update(
          'gunung',
          {
            'nama': item['nama']?.toString(),
            'tercantum': 1,
            'payload': payload,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await _writeMetadata(transaction, 'gunung_list_last_sync', checkedAt);
    });
  }

  Future<Map<String, dynamic>?> readDetail(int id) async {
    final db = await _db;
    final volcanoRows = await db.query(
      'gunung',
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (volcanoRows.isEmpty) return null;
    final reportRows = await db.query(
      'laporan_gunung',
      columns: ['payload'],
      where: 'gunung_id = ?',
      whereArgs: [id],
      orderBy: 'waktu_publikasi DESC, id DESC',
    );
    return {
      'gunung': _decode(volcanoRows.first['payload'] as String),
      'laporan': reportRows
          .map((row) => _decode(row['payload'] as String))
          .toList(),
    };
  }

  Future<void> saveDetail(
    Map<String, dynamic> detail, {
    required DateTime checkedAt,
  }) async {
    final volcano = detail['gunung'];
    final reports = detail['laporan'];
    if (volcano is! Map ||
        reports is! List ||
        reports.any((item) => item is! Map)) {
      throw const FormatException('Format detail gunung tidak sesuai.');
    }
    final gunung = Map<String, dynamic>.from(volcano);
    final id = _requiredId(gunung['id'], 'gunung');
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.insert('gunung', {
        'id': id,
        'nama': gunung['nama']?.toString(),
        'aktif': 1,
        'tercantum': 0,
        'payload': jsonEncode(gunung),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await transaction.update(
        'gunung',
        {'nama': gunung['nama']?.toString(), 'payload': jsonEncode(gunung)},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Detail API returns the complete report collection for this volcano.
      await transaction.delete(
        'laporan_gunung',
        where: 'gunung_id = ?',
        whereArgs: [id],
      );
      for (final rawReport in reports) {
        final report = Map<String, dynamic>.from(rawReport as Map);
        final reportId = _requiredId(report['id'], 'laporan');
        if (_requiredId(report['gunung_id'], 'laporan.gunung_id') != id) {
          throw const FormatException('Relasi laporan gunung tidak sesuai.');
        }
        await transaction.insert('laporan_gunung', {
          'id': reportId,
          'gunung_id': id,
          'waktu_publikasi': report['waktu_publikasi']?.toString(),
          'payload': jsonEncode(report),
        });
      }
      await _writeMetadata(transaction, 'gunung_detail_$id', checkedAt);
    });
  }

  @override
  Future<DateTime?> readLastSync(String key) async {
    final rows = await (await _db).query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String)?.toLocal();
  }

  Future<List<Map<String, dynamic>>> readNews() async {
    final rows = await (await _db).query(
      'news_cache',
      columns: ['payload'],
      orderBy: 'server_order ASC',
    );
    return rows.map((row) => _decode(row['payload'] as String)).toList();
  }

  Future<void> saveNews(
    List<Map<String, dynamic>> items, {
    required DateTime checkedAt,
  }) async {
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.delete('news_cache');
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final id = item['id']?.toString().trim();
        if (id == null || id.isEmpty) {
          throw const FormatException('ID berita tidak valid.');
        }
        await transaction.insert('news_cache', {
          'id': id,
          'server_order': index,
          'payload': jsonEncode(item),
        });
      }
      await _writeMetadata(transaction, 'news_last_sync', checkedAt);
    });
  }

  Future<bool> saveNewsIfChanged(
    List<Map<String, dynamic>> items, {
    required DateTime checkedAt,
  }) async {
    final db = await _db;
    return db.transaction((transaction) async {
      final rows = await transaction.query(
        'news_cache',
        columns: ['payload'],
        orderBy: 'server_order ASC',
      );
      final cachedItems = rows
          .map((row) => _decode(row['payload'] as String))
          .toList();
      final hasUpdates = jsonEncode(cachedItems) != jsonEncode(items);
      if (hasUpdates) {
        await transaction.delete('news_cache');
        for (var index = 0; index < items.length; index++) {
          final item = items[index];
          final id = item['id']?.toString().trim();
          if (id == null || id.isEmpty) {
            throw const FormatException('ID berita tidak valid.');
          }
          await transaction.insert('news_cache', {
            'id': id,
            'server_order': index,
            'payload': jsonEncode(item),
          });
        }
      }
      await _writeMetadata(transaction, 'news_last_sync', checkedAt);
      return hasUpdates;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> readNotifications() async {
    final rows = await (await _db).query(
      'notification_cache',
      columns: ['payload'],
      orderBy: 'server_order ASC',
    );
    return rows.map((row) => _decode(row['payload'] as String)).toList();
  }

  @override
  Future<void> saveNotifications(
    List<Map<String, dynamic>> items, {
    required DateTime checkedAt,
    DateTime? sourceUpdatedAt,
  }) async {
    final db = await _db;
    await db.transaction((transaction) async {
      await transaction.delete('notification_cache');
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final id = item['id']?.toString().trim();
        if (id == null || id.isEmpty) {
          throw const FormatException('ID notifikasi tidak valid.');
        }
        await transaction.insert('notification_cache', {
          'id': id,
          'server_order': index,
          'payload': jsonEncode(item),
        });
      }
      await _writeMetadata(transaction, 'notifications_last_sync', checkedAt);
      if (sourceUpdatedAt == null) {
        await transaction.delete(
          'metadata',
          where: 'key = ?',
          whereArgs: ['notifications_source_last_sync'],
        );
      } else {
        await _writeMetadata(
          transaction,
          'notifications_source_last_sync',
          sourceUpdatedAt,
        );
      }
    });
  }

  Future<void> _writeMetadata(
    Transaction transaction,
    String key,
    DateTime checkedAt,
  ) async {
    await transaction.insert('metadata', {
      'key': key,
      'value': checkedAt.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Map<String, dynamic> _decode(String payload) =>
      Map<String, dynamic>.from(jsonDecode(payload) as Map);

  Future<void> _createNewsTable(DatabaseExecutor db) => db.execute('''
    CREATE TABLE news_cache (
      id TEXT PRIMARY KEY,
      server_order INTEGER NOT NULL,
      payload TEXT NOT NULL
    )
  ''');

  Future<void> _createNotificationsTable(DatabaseExecutor db) => db.execute('''
    CREATE TABLE notification_cache (
      id TEXT PRIMARY KEY,
      server_order INTEGER NOT NULL,
      payload TEXT NOT NULL
    )
  ''');

  int _requiredId(dynamic value, String field) {
    final id = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (id == null) throw FormatException('ID $field tidak valid.');
    return id;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }
}
