// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loans_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global loans notifier - single source of truth for loans and reservations

@ProviderFor(LoansNotifier)
final loansProvider = LoansNotifierProvider._();

/// Global loans notifier - single source of truth for loans and reservations
final class LoansNotifierProvider
    extends $NotifierProvider<LoansNotifier, LoansState> {
  /// Global loans notifier - single source of truth for loans and reservations
  LoansNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loansProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loansNotifierHash();

  @$internal
  @override
  LoansNotifier create() => LoansNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoansState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoansState>(value),
    );
  }
}

String _$loansNotifierHash() => r'a66a56842bb02f0a5dd976d1e4a14a18df66cdd9';

/// Global loans notifier - single source of truth for loans and reservations

abstract class _$LoansNotifier extends $Notifier<LoansState> {
  LoansState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LoansState, LoansState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoansState, LoansState>,
              LoansState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
