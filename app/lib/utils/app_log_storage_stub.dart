class AppLogStorage {
  Future<void> init() async {}

  void append(String content) {}

  Future<void> flush() async {}

  void clear() {}

  Future<String> export(String content) {
    throw UnsupportedError('Log export is not available on this platform.');
  }
}

AppLogStorage createPlatformAppLogStorage() => AppLogStorage();
