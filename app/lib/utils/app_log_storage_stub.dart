class AppLogStorage {
  Future<void> init() async {}

  void append(String content) {}

  void clear() {}

  Future<String> export(String content) {
    throw UnsupportedError('Log export is not available on this platform.');
  }
}

AppLogStorage createPlatformAppLogStorage() => AppLogStorage();
