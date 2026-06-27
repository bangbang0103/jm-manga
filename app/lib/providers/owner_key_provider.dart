import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_provider.dart';
import 'device_provider.dart';

final ownerKeyProvider = Provider<String>((ref) {
  final account = ref.watch(selectedAccountProvider);
  final deviceId = ref.watch(deviceIdProvider);
  final normalizedUsername = account?.username?.trim();
  if (normalizedUsername != null && normalizedUsername.isNotEmpty) {
    return 'jm:$normalizedUsername';
  }
  final normalizedDeviceId = deviceId?.trim();
  if (normalizedDeviceId != null && normalizedDeviceId.isNotEmpty) {
    return 'device:$normalizedDeviceId';
  }
  return 'device:pending';
});
