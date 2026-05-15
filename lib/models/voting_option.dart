// lib/models/voting_option.dart

class VotingOption {
  final String id;
  final String roomId;
  final String label;
  final int position;

  const VotingOption({
    required this.id,
    required this.roomId,
    required this.label,
    required this.position,
  });

  factory VotingOption.fromJson(Map<String, dynamic> json) {
    return VotingOption(
      id: json['id'] as String,
      roomId: json['roomid'] as String,
      label: json['label'] as String,
      position: json['position'] as int? ?? 0,
    );
  }

  VotingOption copyWith({String? id, String? roomId, String? label, int? position}) {
    return VotingOption(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      label: label ?? this.label,
      position: position ?? this.position,
    );
  }
}