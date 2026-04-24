import 'dart:convert';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category;
  final String recipientType;
  final String? recipientId;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final bool read;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.recipientType,
    required this.metadata,
    required this.read,
    required this.createdAt,
    required this.updatedAt,
    this.recipientId,
    this.entityType,
    this.entityId,
    this.readAt,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? recipientType,
    String? recipientId,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    bool? read,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      recipientType: recipientType ?? this.recipientType,
      recipientId: recipientId ?? this.recipientId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      metadata: metadata ?? this.metadata,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      recipientType: map['recipient_type']?.toString() ?? '',
      recipientId: map['recipient_id']?.toString(),
      entityType: map['entity_type']?.toString(),
      entityId: map['entity_id']?.toString(),
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      read: map['read'] as bool? ?? false,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      readAt: parseNullableDate(map['read_at']),
    );
  }

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source) as Map<String, dynamic>);
}
