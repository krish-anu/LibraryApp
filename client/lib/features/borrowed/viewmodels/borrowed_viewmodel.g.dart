// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'borrowed_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BorrowedViewModel)
final borrowedViewModelProvider = BorrowedViewModelProvider._();

final class BorrowedViewModelProvider
    extends $NotifierProvider<BorrowedViewModel, BorrowedState> {
  BorrowedViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'borrowedViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$borrowedViewModelHash();

  @$internal
  @override
  BorrowedViewModel create() => BorrowedViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BorrowedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BorrowedState>(value),
    );
  }
}

String _$borrowedViewModelHash() => r'02e38bbc2ee4ff6daff395ceb50460b0755db7c8';

abstract class _$BorrowedViewModel extends $Notifier<BorrowedState> {
  BorrowedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BorrowedState, BorrowedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BorrowedState, BorrowedState>,
              BorrowedState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
