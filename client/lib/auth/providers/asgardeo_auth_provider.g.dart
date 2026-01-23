// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asgardeo_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Asgardeo Authentication Provider

@ProviderFor(AsgardeoAuth)
final asgardeoAuthProvider = AsgardeoAuthProvider._();

/// Asgardeo Authentication Provider
final class AsgardeoAuthProvider
    extends $NotifierProvider<AsgardeoAuth, AsgardeoAuthState> {
  /// Asgardeo Authentication Provider
  AsgardeoAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asgardeoAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asgardeoAuthHash();

  @$internal
  @override
  AsgardeoAuth create() => AsgardeoAuth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsgardeoAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsgardeoAuthState>(value),
    );
  }
}

String _$asgardeoAuthHash() => r'1cf869a4bd9d232022fb7ddce0ab74970a922eb2';

/// Asgardeo Authentication Provider

abstract class _$AsgardeoAuth extends $Notifier<AsgardeoAuthState> {
  AsgardeoAuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsgardeoAuthState, AsgardeoAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsgardeoAuthState, AsgardeoAuthState>,
              AsgardeoAuthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
