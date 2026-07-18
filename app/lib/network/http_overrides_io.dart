import 'dart:io';

/// 全局强制所有非 dio 的 Dart HttpClient 直连（不经过系统代理）。
///
/// 意图：App 的代理设置由 dio 层统一处理（见 configureDioProxy），
/// 图片/解码等不走 dio 的系统流量如果静默使用系统代理，会出现
/// “开了代理但部分流量没走代理”或反之的难以排查的不一致。
/// 统一 DIRECT 后，是否走代理只取决于 dio 的配置，行为可预期。
class _NoProxyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..findProxy = (uri) => 'DIRECT';
  }
}

void configurePlatformNoProxyHttpOverrides() {
  HttpOverrides.global = _NoProxyHttpOverrides();
}
