import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> createTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return openDatabase(
    inMemoryDatabasePath,
    version: 2,
    onCreate: (db, version) async {
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
      await db.execute('''
        CREATE TABLE chapter_manifests (
          photo_id TEXT PRIMARY KEY,
          album_id TEXT NOT NULL,
          title TEXT NOT NULL,
          image_names TEXT NOT NULL,
          page_count INTEGER NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_chapter_manifests_album
        ON chapter_manifests(album_id)
      ''');
    },
  );
}
