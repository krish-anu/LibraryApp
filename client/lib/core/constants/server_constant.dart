class ServerConstant {
  static const String _envServer = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: '',
  );
  static bool _logged = false;

  static String get serverURL {
    if (_envServer.isNotEmpty) {
      if (!_logged) {
        // ignore: avoid_print
        print('ServerConstant: using SERVER_URL override -> $_envServer');
        _logged = true;
      }
      return _envServer;
    }

    // Default to the host loopback. For physical Android devices using
    // `adb reverse tcp:8000 tcp:8000`, `http://127.0.0.1:8000` reaches the
    // host machine. If you're using an Android emulator, pass the emulator
    // host address explicitly when running the app:
    // `flutter run --dart-define=SERVER_URL=http://10.0.2.2:8000`
    final url = 'http://127.0.0.1:8000';
    if (!_logged) {
      // ignore: avoid_print
      print('ServerConstant: resolved serverURL -> $url');
      _logged = true;
    }
    return url;
  }
}
