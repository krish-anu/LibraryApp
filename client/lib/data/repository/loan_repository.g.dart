// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loanRepository)
final loanRepositoryProvider = LoanRepositoryProvider._();

final class LoanRepositoryProvider
    extends $FunctionalProvider<LoanRepository, LoanRepository, LoanRepository>
    with $Provider<LoanRepository> {
  LoanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loanRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loanRepositoryHash();

  @$internal
  @override
  $ProviderElement<LoanRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoanRepository create(Ref ref) {
    return loanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoanRepository>(value),
    );
  }
}

String _$loanRepositoryHash() => r'000fdbe43943bbbc5046be782ed40facf8a5e4ae';

@ProviderFor(fetchAllLoans)
final fetchAllLoansProvider = FetchAllLoansProvider._();

final class FetchAllLoansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Loan>>,
          List<Loan>,
          FutureOr<List<Loan>>
        >
    with $FutureModifier<List<Loan>>, $FutureProvider<List<Loan>> {
  FetchAllLoansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fetchAllLoansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fetchAllLoansHash();

  @$internal
  @override
  $FutureProviderElement<List<Loan>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Loan>> create(Ref ref) {
    return fetchAllLoans(ref);
  }
}

String _$fetchAllLoansHash() => r'294636707ec667821a2ccaf37e74fbe60ea5bdbb';

@ProviderFor(fetchActiveLoans)
final fetchActiveLoansProvider = FetchActiveLoansFamily._();

final class FetchActiveLoansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Loan>>,
          List<Loan>,
          FutureOr<List<Loan>>
        >
    with $FutureModifier<List<Loan>>, $FutureProvider<List<Loan>> {
  FetchActiveLoansProvider._({
    required FetchActiveLoansFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'fetchActiveLoansProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchActiveLoansHash();

  @override
  String toString() {
    return r'fetchActiveLoansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Loan>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Loan>> create(Ref ref) {
    final argument = this.argument as String?;
    return fetchActiveLoans(ref, memberId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchActiveLoansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchActiveLoansHash() => r'8b7d9a8e2d5d66cecf140c57800ce3fa1258d19a';

final class FetchActiveLoansFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Loan>>, String?> {
  FetchActiveLoansFamily._()
    : super(
        retry: null,
        name: r'fetchActiveLoansProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchActiveLoansProvider call({String? memberId}) =>
      FetchActiveLoansProvider._(argument: memberId, from: this);

  @override
  String toString() => r'fetchActiveLoansProvider';
}
