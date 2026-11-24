import 'package:flutter/foundation.dart';

/// Base URL for the Laravel API in `API-CHAT`.
///
/// Override at run time with `--dart-define=API_BASE=http://192.168.0.10:8001`
/// when the phone is not on the same machine as the emulator.
String get apiBaseUrl {
  const override = String.fromEnvironment('API_BASE');
  if (override.isNotEmpty) {
    return override;
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8001';
  }
  return 'http://127.0.0.1:8001';
}
