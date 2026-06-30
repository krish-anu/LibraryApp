import 'package:flutter/foundation.dart';

class ServerConstant {
  static const String _envServer = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: '',
  );

  static String get serverURL {
    if (_envServer.isNotEmpty) {
      if (kReleaseMode && _envServer.startsWith('http://')) {
        throw StateError('SERVER_URL must use HTTPS in release builds.');
      }
      return _envServer;
    }

    // Default to the host loopback. For physical Android devices using
    // `adb reverse tcp:8000 tcp:8000`, `http://127.0.0.1:8000` reaches the
    // host machine. If you're using an Android emulator, pass the emulator
    // host address explicitly when running the app:
    // `flutter run --dart-define=SERVER_URL=http://10.0.2.2:8000`
    return 'http://127.0.0.1:8000';
  }
}
