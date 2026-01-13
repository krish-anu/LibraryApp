// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'8366fba5ac0d6b90c6a637882d24c5e759a5a92f';

@ProviderFor(fetchUserProfile)
final fetchUserProfileProvider = FetchUserProfileFamily._();

final class FetchUserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          FutureOr<UserProfile>
        >
    with $FutureModifier<UserProfile>, $FutureProvider<UserProfile> {
  FetchUserProfileProvider._({
    required FetchUserProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserProfileHash();

  @override
  String toString() {
    return r'fetchUserProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserProfileHash() => r'b469ac811560772cda172a55e3404bb7affe497c';

final class FetchUserProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<UserProfile>, String> {
  FetchUserProfileFamily._()
    : super(
        retry: null,
        name: r'fetchUserProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchUserProfileProvider call(String userId) =>
      FetchUserProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'fetchUserProfileProvider';
}

@ProviderFor(fetchUserStats)
final fetchUserStatsProvider = FetchUserStatsFamily._();

final class FetchUserStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProfileStats>,
          ProfileStats,
          FutureOr<ProfileStats>
        >
    with $FutureModifier<ProfileStats>, $FutureProvider<ProfileStats> {
  FetchUserStatsProvider._({
    required FetchUserStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchUserStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchUserStatsHash();

  @override
  String toString() {
    return r'fetchUserStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProfileStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProfileStats> create(Ref ref) {
    final argument = this.argument as String;
    return fetchUserStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchUserStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchUserStatsHash() => r'93683f1d27fc53b52a505aa8449ff7b17c0c393f';

final class FetchUserStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProfileStats>, String> {
  FetchUserStatsFamily._()
    : super(
        retry: null,
        name: r'fetchUserStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchUserStatsProvider call(String userId) =>
      FetchUserStatsProvider._(argument: userId, from: this);

  @override
  String toString() => r'fetchUserStatsProvider';
}
