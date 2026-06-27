import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _instance;

  static Future<Database> get instance async => _instance ??= await _open();

  static Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'jm_manga.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_key TEXT NOT NULL,
        album_id TEXT NOT NULL,
        photo_id TEXT NOT NULL,
        title TEXT,
        image_index INTEGER NOT NULL DEFAULT 0,
        is_finished INTEGER NOT NULL DEFAULT 0,
        last_read_at TEXT NOT NULL,
        episode_index INTEGER,
        page_count INTEGER,
        cached_at TEXT NOT NULL,
        UNIQUE(owner_key, album_id, photo_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_progress_owner_album
      ON reading_progress(owner_key, album_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_progress_owner_last_read
      ON reading_progress(owner_key, last_read_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_key TEXT NOT NULL,
        album_id TEXT NOT NULL,
        title TEXT NOT NULL,
        cover_url TEXT,
        sync_status TEXT,
        cached_at TEXT NOT NULL,
        UNIQUE(owner_key, album_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_favorites_owner
      ON favorites(owner_key)
    ''');
  }
}
