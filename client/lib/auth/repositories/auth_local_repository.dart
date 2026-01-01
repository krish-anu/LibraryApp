import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_local_repository.g.dart';

@Riverpod(keepAlive: true)
AuthLocalRepository authLocalRepository(Ref ref) {
  return AuthLocalRepository();
}

class AuthLocalRepository {
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> init() async {
    if (_sharedPreferences != null) {
      return _sharedPreferences!;
    }
    _sharedPreferences = await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  Future<void> setToken(String? token) async {
    if (token == null) {
      return;
    }
    final prefs = await init();
    await prefs.setString('x-auth-token', token);
  }

  Future<String?> getToken() async {
    final prefs = await init();
    return prefs.getString('x-auth-token');
  }
}
