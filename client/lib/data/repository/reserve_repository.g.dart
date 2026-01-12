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

@ProviderFor(fetchReservationsByMember)
final fetchReservationsByMemberProvider = FetchReservationsByMemberFamily._();

final class FetchReservationsByMemberProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Reserve>>,
          List<Reserve>,
          FutureOr<List<Reserve>>
        >
    with $FutureModifier<List<Reserve>>, $FutureProvider<List<Reserve>> {
  FetchReservationsByMemberProvider._({
    required FetchReservationsByMemberFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchReservationsByMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchReservationsByMemberHash();

  @override
  String toString() {
    return r'fetchReservationsByMemberProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Reserve>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Reserve>> create(Ref ref) {
    final argument = this.argument as String;
    return fetchReservationsByMember(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchReservationsByMemberProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchReservationsByMemberHash() =>
    r'3763131a9efc0c36f869b520662adaa543e042b4';

final class FetchReservationsByMemberFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Reserve>>, String> {
  FetchReservationsByMemberFamily._()
    : super(
        retry: null,
        name: r'fetchReservationsByMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchReservationsByMemberProvider call(String memberId) =>
      FetchReservationsByMemberProvider._(argument: memberId, from: this);

  @override
  String toString() => r'fetchReservationsByMemberProvider';
}
