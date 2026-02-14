// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asgardeo_direct_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for direct Asgardeo authentication

@ProviderFor(AsgardeoDirectAuth)
final asgardeoDirectAuthProvider = AsgardeoDirectAuthProvider._();

/// Provider for direct Asgardeo authentication
final class AsgardeoDirectAuthProvider
    extends $NotifierProvider<AsgardeoDirectAuth, AsgardeoDirectState> {
  /// Provider for direct Asgardeo authentication
  AsgardeoDirectAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asgardeoDirectAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asgardeoDirectAuthHash();

  @$internal
  @override
  AsgardeoDirectAuth create() => AsgardeoDirectAuth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsgardeoDirectState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsgardeoDirectState>(value),
    );
  }
}

String _$asgardeoDirectAuthHash() =>
    r'ec1565f9ca666d3358daa8b7fa69cda48f692ffd';

/// Provider for direct Asgardeo authentication

abstract class _$AsgardeoDirectAuth extends $Notifier<AsgardeoDirectState> {
  AsgardeoDirectState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsgardeoDirectState, AsgardeoDirectState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsgardeoDirectState, AsgardeoDirectState>,
              AsgardeoDirectState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
