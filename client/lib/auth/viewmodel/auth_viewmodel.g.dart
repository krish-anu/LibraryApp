// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthViewModel)
const authViewModelProvider = AuthViewModelProvider._();

final class AuthViewModelProvider
    extends $NotifierProvider<AuthViewModel, AsyncValue<User>?> {
  const AuthViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authViewModelHash();

  @$internal
  @override
  AuthViewModel create() => AuthViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<User>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<User>?>(value),
    );
  }
}

String _$authViewModelHash() => r'd2940d64caa05aaaa5f1c2beda87a0f7acacfe43';

abstract class _$AuthViewModel extends $Notifier<AsyncValue<User>?> {
  AsyncValue<User>? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<User>?, AsyncValue<User>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<User>?, AsyncValue<User>?>,
              AsyncValue<User>?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
