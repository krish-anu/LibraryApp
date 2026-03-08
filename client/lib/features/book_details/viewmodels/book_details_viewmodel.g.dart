// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_details_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BookDetailsViewModel)
final bookDetailsViewModelProvider = BookDetailsViewModelFamily._();

final class BookDetailsViewModelProvider
    extends $NotifierProvider<BookDetailsViewModel, BookDetailsState> {
  BookDetailsViewModelProvider._({
    required BookDetailsViewModelFamily super.from,
    required Book super.argument,
  }) : super(
         retry: null,
         name: r'bookDetailsViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookDetailsViewModelHash();

  @override
  String toString() {
    return r'bookDetailsViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookDetailsViewModel create() => BookDetailsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookDetailsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookDetailsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookDetailsViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookDetailsViewModelHash() =>
    r'ae4cbef2e33ea3bf07d3421f1ff08e70d7f06b99';

final class BookDetailsViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          BookDetailsViewModel,
          BookDetailsState,
          BookDetailsState,
          BookDetailsState,
          Book
        > {
  BookDetailsViewModelFamily._()
    : super(
        retry: null,
        name: r'bookDetailsViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookDetailsViewModelProvider call(Book book) =>
      BookDetailsViewModelProvider._(argument: book, from: this);

  @override
  String toString() => r'bookDetailsViewModelProvider';
}

abstract class _$BookDetailsViewModel extends $Notifier<BookDetailsState> {
  late final _$args = ref.$arg as Book;
  Book get book => _$args;

  BookDetailsState build(Book book);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BookDetailsState, BookDetailsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookDetailsState, BookDetailsState>,
              BookDetailsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
