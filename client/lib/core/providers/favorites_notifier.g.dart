// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global favorites notifier - single source of truth for favorites

@ProviderFor(FavoritesNotifier)
final favoritesProvider = FavoritesNotifierProvider._();

/// Global favorites notifier - single source of truth for favorites
final class FavoritesNotifierProvider
    extends $NotifierProvider<FavoritesNotifier, FavoritesState> {
  /// Global favorites notifier - single source of truth for favorites
  FavoritesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesNotifierHash();

  @$internal
  @override
  FavoritesNotifier create() => FavoritesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritesState>(value),
    );
  }
}

String _$favoritesNotifierHash() => r'04305a70625ba5a61830538d991d20194cf1155c';

/// Global favorites notifier - single source of truth for favorites

abstract class _$FavoritesNotifier extends $Notifier<FavoritesState> {
  FavoritesState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FavoritesState, FavoritesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavoritesState, FavoritesState>,
              FavoritesState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
