// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserve_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reserveRepository)
final reserveRepositoryProvider = ReserveRepositoryProvider._();

final class ReserveRepositoryProvider
    extends
        $FunctionalProvider<
          ReserveRepository,
          ReserveRepository,
          ReserveRepository
        >
    with $Provider<ReserveRepository> {
  ReserveRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reserveRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reserveRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReserveRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReserveRepository create(Ref ref) {
    return reserveRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReserveRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReserveRepository>(value),
    );
  }
}

String _$reserveRepositoryHash() => r'f959221f9738c5787a0e00414ac6e8a59dd1d845';
