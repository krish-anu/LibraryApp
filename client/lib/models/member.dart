// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Member {
  final String id;
  final String firstName;
  final String lastNAme;
  final DateTime joinedDate;
  final String status;
  Member({
    required this.id,
    required this.firstName,
    required this.lastNAme,
    required this.joinedDate,
    required this.status,
  });

  Member copyWith({
    String? id,
    String? firstName,
    String? lastNAme,
    DateTime? joinedDate,
    String? status,
  }) {
    return Member(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastNAme: lastNAme ?? this.lastNAme,
      joinedDate: joinedDate ?? this.joinedDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastNAme': lastNAme,
      'joinedDate': joinedDate.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastNAme: map['lastNAme'] as String,
      joinedDate: DateTime.fromMillisecondsSinceEpoch(map['joinedDate'] as int),
      status: map['status'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Member.fromJson(String source) => Member.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Member(id: $id, firstName: $firstName, lastNAme: $lastNAme, joinedDate: $joinedDate, status: $status)';
  }

  @override
  bool operator ==(covariant Member other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.firstName == firstName &&
      other.lastNAme == lastNAme &&
      other.joinedDate == joinedDate &&
      other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      firstName.hashCode ^
      lastNAme.hashCode ^
      joinedDate.hashCode ^
      status.hashCode;
  }
}
