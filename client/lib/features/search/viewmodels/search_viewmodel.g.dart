// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchViewModel)
final searchViewModelProvider = SearchViewModelFamily._();

final class SearchViewModelProvider
    extends $NotifierProvider<SearchViewModel, SearchState> {
  SearchViewModelProvider._({
    required SearchViewModelFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'searchViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchViewModelHash();

  @override
  String toString() {
    return r'searchViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SearchViewModel create() => SearchViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchViewModelHash() => r'0d1f94168ad731b3feeaccc75200135b9fa9b511';

final class SearchViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchViewModel,
          SearchState,
          SearchState,
          SearchState,
          String?
        > {
  SearchViewModelFamily._()
    : super(
        retry: null,
        name: r'searchViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchViewModelProvider call({String? initialCategory}) =>
      SearchViewModelProvider._(argument: initialCategory, from: this);

  @override
  String toString() => r'searchViewModelProvider';
}

abstract class _$SearchViewModel extends $Notifier<SearchState> {
  late final _$args = ref.$arg as String?;
  String? get initialCategory => _$args;

  SearchState build({String? initialCategory});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(initialCategory: _$args));
  }
}
