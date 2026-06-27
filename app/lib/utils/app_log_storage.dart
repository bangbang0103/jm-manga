import 'app_log_storage_stub.dart'
    if (dart.library.io) 'app_log_storage_io.dart';

AppLogStorage createAppLogStorage() => createPlatformAppLogStorage();
