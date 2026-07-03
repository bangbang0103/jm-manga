import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../models/album.dart';
import '../models/reading_progress.dart';

abstract interface class MangaRepository {
  Future<List<AlbumItem>> search(String query, {int page = 1});

  Future<List<AlbumItem>> getRankings(
    String type, {
    String category = '0',
    int page = 1,
  });

  Future<List<AlbumItem>> getCategories({
    String category = '0',
    String orderBy = 'mr',
    int page = 1,
  });

  Future<AlbumDetail> getAlbumDetail(String albumId);

  Future<PhotoDetail> getPhotoDetail(String photoId);

  String coverUrl(String albumId, {String size = ''});

  Map<String, String> get imageHeaders;

  ImageProvider imageProvider(String url);

  Future<Uint8List> downloadImage(String url);

  Future<List<AlbumItem>> getFavorites({String folderId = '0', int page = 1});

  Future<Map<String, dynamic>> syncFavorites({
    String folderId = '0',
    int page = 1,
    bool force = false,
    bool full = false,
  });

  Future<Map<String, dynamic>> toggleFavorite(
    String albumId, {
    AlbumItem? item,
  });

  Future<List<ReadingProgress>> getRecentProgress();

  Future<List<ReadingProgress>> searchRecentProgress(String query);

  Future<List<ReadingProgress>> getAlbumProgress(String albumId);

  Future<void> syncProgress(ReadingProgress progress);

  Future<void> deleteRecentProgress(List<String> albumIds);

  Future<Map<String, dynamic>> checkHealth();

  Future<Map<String, dynamic>> validateConnection();

  Future<Map<String, dynamic>> loginToJm(String username, String password);

  Future<Map<String, dynamic>> testJmLogin(String username, String password);
}
