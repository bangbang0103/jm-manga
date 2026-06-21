import 'dart:io';

class _NoProxyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..findProxy = (uri) => 'DIRECT';
  }
}

void configurePlatformNoProxyHttpOverrides() {
  HttpOverrides.global = _NoProxyHttpOverrides();
}
