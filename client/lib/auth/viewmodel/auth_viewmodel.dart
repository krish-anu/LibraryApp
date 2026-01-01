// ignore_for_file: only_use_keep_alive_inside_keep_alive

import 'package:fpdart/fpdart.dart';
import 'package:libraryapp/auth/repositories/auth_local_repository.dart';
import 'package:libraryapp/auth/repositories/auth_remote_repository.dart';
import 'package:libraryapp/core/providers/current_user_notifier.dart';
import 'package:libraryapp/models/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_viewmodel.g.dart';

@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  late AuthRemoteRepository _authRemoteRepository;
  late AuthLocalRepository _authLocalRepository;
  late CurrentUserNotifier _currentUserNotifier;

  @override
  AsyncValue<User>? build() {
    _authRemoteRepository = ref.watch(authRemoteRepositoryProvider);
    _authLocalRepository = ref.watch(authLocalRepositoryProvider);
    _currentUserNotifier = ref.watch(currentUserProvider.notifier);
    return null;
  }

  Future<void> initSharedPreferences() async {
    await _authLocalRepository.init();
  }

  Future<void> signUpUser(String name, String email, String password) async {
    state = AsyncValue.loading();

    final res = await _authRemoteRepository.signup(name, email, password);
    // ignore: unused_local_variable
    final val = switch (res) {
      Left(value: final l) => state = AsyncValue.error(
        l.message,
        StackTrace.current,
      ),
      Right(value: final r) => state = AsyncValue.data(r),
    };

    // update state appropriately
    print(res);
  }

  Future<void> loginUser(String email, String password) async {
    state = AsyncValue.loading();

    final res = await _authRemoteRepository.login(email, password);
    // ignore: unused_local_variable
    final val = switch (res) {
      Left(value: final l) => state = AsyncValue.error(
        l.message,
        StackTrace.current,
      ),
      Right(value: final r) => await _loginSuccess(r),
    };

    // update state appropriately
    print(res);
  }

  Future<void> _loginSuccess(User user) async {
    await _authLocalRepository.setToken(user.token);
    _currentUserNotifier.addUser(user);
    state = AsyncValue.data(user);
  }

  Future<User?> getData() async {
    state = const AsyncValue.loading();
    final token = await _authLocalRepository.getToken();
    if (token != null) {
      final res = await _authRemoteRepository.getCurrentUserData(token);
      return switch (res) {
        Left(value: final l) => () {
          state = AsyncValue.error(l.message, StackTrace.current);
          return null;
        }(),
        Right(value: final user) => () {
          _getDataSuccess(user);
          return user; // 👈 pure User
        }(),
      };
    }

    return null;
  }

  AsyncValue<User> _getDataSuccess(User user) {
    _currentUserNotifier.addUser(user);
    return state = AsyncValue.data(user);
  }
}
