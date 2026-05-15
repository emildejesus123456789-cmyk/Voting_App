// lib/models/room.dart

class Room {
  final String id;
  final String title;
  final String code;
  final String? createdBy;
  final bool isOpen;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.title,
    required this.code,
    this.createdBy,
    required this.isOpen,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      createdBy: json['createdby'] as String?,
      isOpen: json['isopen'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdat'] as String),
    );
  }

  Room copyWith({
    String? id,
    String? title,
    String? code,
    String? createdBy,
    bool? isOpen,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}