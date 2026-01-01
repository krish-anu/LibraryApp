// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class User {
  String userName;
  String email;
  String id;
  String token;
  User({
    required this.userName,
    required this.email,
    required this.id,
    required this.token,
  });
  

  User copyWith({
    String? userName,
    String? email,
    String? id,
    String? token,
  }) {
    return User(
      userName: userName ?? this.userName,
      email: email ?? this.email,
      id: id ?? this.id,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userName': userName,
      'email': email,
      'id': id,
      'token': token,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userName: map['userName'] as String,
      email: map['email'] as String,
      id: map['id'] as String,
      token: map['token'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(userName: $userName, email: $email, id: $id, token: $token)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;
  
    return 
      other.userName == userName &&
      other.email == email &&
      other.id == id &&
      other.token == token;
  }

  @override
  int get hashCode {
    return userName.hashCode ^
      email.hashCode ^
      id.hashCode ^
      token.hashCode;
  }
}
