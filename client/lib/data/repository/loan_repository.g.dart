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

String _$loanRepositoryHash() => r'531b277cb6ddf91646f627ba297a8fc4ab0c386b';

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

String _$fetchAllLoansHash() => r'aaa8b1d69c9467839589199f405e9188b7ad43d7';
