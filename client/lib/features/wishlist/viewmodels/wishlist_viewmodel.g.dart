// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WishlistViewModel)
final wishlistViewModelProvider = WishlistViewModelProvider._();

final class WishlistViewModelProvider
    extends $NotifierProvider<WishlistViewModel, WishlistState> {
  WishlistViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wishlistViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wishlistViewModelHash();

  @$internal
  @override
  WishlistViewModel create() => WishlistViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WishlistState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WishlistState>(value),
    );
  }
}

String _$wishlistViewModelHash() => r'db6b7ad60e56abdb82550d5b85cab9699d824fb0';

abstract class _$WishlistViewModel extends $Notifier<WishlistState> {
  WishlistState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WishlistState, WishlistState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WishlistState, WishlistState>,
              WishlistState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
