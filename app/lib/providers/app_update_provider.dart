import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_update_info.dart';
import '../models/app_version.dart';
import '../services/app_update_service.dart';
import 'config_provider.dart';

/// The state of the in-app update check.
class AppUpdateState {
  final bool isChecking;
  final String currentVersion;
  final AppUpdateInfo? latestInfo;
  final Object? error;

  const AppUpdateState({
    this.isChecking = false,
    this.currentVersion = '',
    this.latestInfo,
    this.error,
  });

  /// Whether the fetched release is newer than the current version.
  bool get hasUpdate {
    final info = latestInfo;
    if (info == null || currentVersion.isEmpty) return false;

    try {
      final latest = AppVersion.parse(info.version);
      final current = AppVersion.parse(currentVersion);
      return latest.isNewerThan(current);
    } on FormatException {
      return false;
    }
  }

  AppUpdateState copyWith({
    bool? isChecking,
    String? currentVersion,
    AppUpdateInfo? latestInfo,
    Object? error,
    bool clearLatestInfo = false,
    bool clearError = false,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      currentVersion: currentVersion ?? this.currentVersion,
      latestInfo: clearLatestInfo ? null : (latestInfo ?? this.latestInfo),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Manages update-check state.
class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final AppUpdateService _service;

  AppUpdateNotifier({required this._service, String currentVersion = ''})
    : super(AppUpdateState(currentVersion: currentVersion));

  void setCurrentVersion(String version) {
    state = state.copyWith(currentVersion: version);
  }

  /// Checks the latest release from the remote source.
  ///
  /// Set [silent] to `true` for background checks (e.g. on app launch) so that
  /// errors are not surfaced to the user.
  Future<void> checkForUpdates({bool silent = false}) async {
    state = state.copyWith(isChecking: true, clearError: true);

    try {
      final info = await _service.fetchLatestRelease();
      state = state.copyWith(
        isChecking: false,
        latestInfo: info,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: silent ? null : e,
      );
    }
  }
}

/// Provides the default [AppUpdateService].
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final proxyUrl = ref.watch(configProvider.select((config) => config.proxyUrl));
  return AppUpdateService(proxyUrl: proxyUrl);
});

/// Provides the in-app update state.
final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
      return AppUpdateNotifier(
        service: ref.watch(appUpdateServiceProvider),
      );
    });
