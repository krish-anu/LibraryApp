// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoritesRepository)
final favoritesRepositoryProvider = FavoritesRepositoryProvider._();

final class FavoritesRepositoryProvider
    extends
        $FunctionalProvider<
          FavoritesRepository,
          FavoritesRepository,
          FavoritesRepository
        >
    with $Provider<FavoritesRepository> {
  FavoritesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoritesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoritesRepository create(Ref ref) {
    return favoritesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritesRepository>(value),
    );
  }
}

String _$favoritesRepositoryHash() =>
    r'a272a36dc265953c6901b12057bc539d8cc98495';

@ProviderFor(fetchFavorites)
final fetchFavoritesProvider = FetchFavoritesFamily._();

final class FetchFavoritesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Book>>,
          List<Book>,
          FutureOr<List<Book>>
        >
    with $FutureModifier<List<Book>>, $FutureProvider<List<Book>> {
  FetchFavoritesProvider._({
    required FetchFavoritesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchFavoritesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchFavoritesHash();

  @override
  String toString() {
    return r'fetchFavoritesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Book>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Book>> create(Ref ref) {
    final argument = this.argument as String;
    return fetchFavorites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchFavoritesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchFavoritesHash() => r'dfb2d700559c83ad51d0107e7b3e7c57068c24b3';

final class FetchFavoritesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Book>>, String> {
  FetchFavoritesFamily._()
    : super(
        retry: null,
        name: r'fetchFavoritesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchFavoritesProvider call(String memberId) =>
      FetchFavoritesProvider._(argument: memberId, from: this);

  @override
  String toString() => r'fetchFavoritesProvider';
}

@ProviderFor(fetchFavoriteIds)
final fetchFavoriteIdsProvider = FetchFavoriteIdsFamily._();

final class FetchFavoriteIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  FetchFavoriteIdsProvider._({
    required FetchFavoriteIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchFavoriteIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchFavoriteIdsHash();

  @override
  String toString() {
    return r'fetchFavoriteIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    final argument = this.argument as String;
    return fetchFavoriteIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchFavoriteIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchFavoriteIdsHash() => r'48b5d571eace37acc41c0a8b5957024a89bf695a';

final class FetchFavoriteIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Set<String>>, String> {
  FetchFavoriteIdsFamily._()
    : super(
        retry: null,
        name: r'fetchFavoriteIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchFavoriteIdsProvider call(String memberId) =>
      FetchFavoriteIdsProvider._(argument: memberId, from: this);

  @override
  String toString() => r'fetchFavoriteIdsProvider';
}
