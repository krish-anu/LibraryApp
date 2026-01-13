// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserProfile {
  final String id;
  final String? memberId;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? profileImage;
  final DateTime? joinedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.memberId,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.profileImage,
    this.joinedDate,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? memberId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? profileImage,
    DateTime? joinedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      joinedDate: joinedDate ?? this.joinedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'member_id': memberId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'joined_date': joinedDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      memberId: map['member_id'] as String?,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      profileImage: map['profile_image'] as String?,
      joinedDate: map['joined_date'] != null
          ? DateTime.tryParse(map['joined_date'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserProfile(id: $id, memberId: $memberId, name: $name, email: $email, phone: $phone, address: $address, profileImage: $profileImage, joinedDate: $joinedDate)';
  }

  @override
  bool operator ==(covariant UserProfile other) {
    if (identical(this, other)) return true;
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
