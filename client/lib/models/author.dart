// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Author {
  final String id;
  final String firstName;
  final String lastName;
  Author({required this.id, required this.firstName, required this.lastName});

  Author copyWith({String? id, String? firstName, String? lastName}) {
    return Author(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  factory Author.fromMap(Map<String, dynamic> map) {
    return Author(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Author.fromJson(String source) =>
      Author.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Author(id: $id, firstName: $firstName, lastName: $lastName)';

  @override
  bool operator ==(covariant Author other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName;
  }

  @override
  int get hashCode => id.hashCode ^ firstName.hashCode ^ lastName.hashCode;
}
