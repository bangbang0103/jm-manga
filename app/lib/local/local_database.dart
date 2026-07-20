import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  static Database? _instance;
  static bool _ffiInitialized = false;

  /// sqflite 原生插件仅支持 iOS/Android/macOS，Windows/Linux 走 ffi。
  static bool get _useFfi =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  static Future<Database> get instance async => _instance ??= await _open();

  static Future<Database> _open() async {
    final String databasesPath;
    if (_useFfi) {
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _ffiInitialized = true;
      }
      // ffi 的默认库目录是进程工作目录，打包后不可控，改用应用支持目录。
      databasesPath = (await getApplicationSupportDirectory()).path;
    } else {
      databasesPath = await getDatabasesPath();
    }
    final path = join(databasesPath, 'jm_manga.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await _createChapterManifests(db);
  }

  static FutureOr<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createChapterManifests(db);
    }
  }

  static Future<void> _createChapterManifests(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chapter_manifests (
        photo_id TEXT PRIMARY KEY,
        album_id TEXT NOT NULL,
        title TEXT NOT NULL,
        image_names TEXT NOT NULL,
        page_count INTEGER NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_chapter_manifests_album
      ON chapter_manifests(album_id)
    ''');
  }
}
