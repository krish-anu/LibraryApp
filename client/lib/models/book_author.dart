// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BookAuthor {
  final String bookId;
  final String authorId;
  BookAuthor({required this.bookId, required this.authorId});

  BookAuthor copyWith({String? bookId, String? authorId}) {
    return BookAuthor(
      bookId: bookId ?? this.bookId,
      authorId: authorId ?? this.authorId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'bookId': bookId, 'authorId': authorId};
  }

  factory BookAuthor.fromMap(Map<String, dynamic> map) {
    return BookAuthor(
      bookId: map['bookId'] as String,
      authorId: map['authorId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory BookAuthor.fromJson(String source) =>
      BookAuthor.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'BookAuthor(bookId: $bookId, authorId: $authorId)';

  @override
  bool operator ==(covariant BookAuthor other) {
    if (identical(this, other)) return true;

    return other.bookId == bookId && other.authorId == authorId;
  }

  @override
  int get hashCode => bookId.hashCode ^ authorId.hashCode;
}
