import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../utils/secure_storage.dart';

final deviceIdProvider = StateNotifierProvider<DeviceIdNotifier, String?>((
  ref,
) {
  return DeviceIdNotifier();
});

class DeviceIdNotifier extends StateNotifier<String?> {
  static const _key = 'jm_manga_device_id';

  DeviceIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final existing = await SecureStorage.read(_key);
    if (existing != null && existing.isNotEmpty) {
      state = existing;
      return;
    }

    final generated = const Uuid().v4();
    await SecureStorage.write(_key, generated);
    state = generated;
  }
}
