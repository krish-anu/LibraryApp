// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final String description;
  final double rating;
  final int publicationYear;
  final int copiesOwned;
  final String image;
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.description,
    required this.rating,
    required this.publicationYear,
    required this.copiesOwned,
    required this.image,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? description,
    double? rating,
    int? publicationYear,
    int? copiesOwned,
    String? image,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      publicationYear: publicationYear ?? this.publicationYear,
      copiesOwned: copiesOwned ?? this.copiesOwned,
      image: image ?? this.image,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'rating': rating,
      'publicationYear': publicationYear,
      'copiesOwned': copiesOwned,
      'image': image,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      rating: map['rating'] as double,
      publicationYear: map['publicationYear'] as int,
      copiesOwned: map['copiesOwned'] as int,
      image: map['image'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Book.fromJson(String source) =>
      Book.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, category: $category, description: $description, rating: $rating, publicationYear: $publicationYear, copiesOwned: $copiesOwned, image: $image)';
  }

  @override
  bool operator ==(covariant Book other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.author == author &&
        other.category == category &&
        other.description == description &&
        other.rating == rating &&
        other.publicationYear == publicationYear &&
        other.copiesOwned == copiesOwned &&
        other.image == image;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        author.hashCode ^
        category.hashCode ^
        description.hashCode ^
        rating.hashCode ^
        publicationYear.hashCode ^
        copiesOwned.hashCode ^
        image.hashCode;
  }
}
