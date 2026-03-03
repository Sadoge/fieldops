class PresenceUser {
  const PresenceUser({
    required this.userId,
    required this.displayName,
    required this.isEditing,
    required this.joinedAt,
  });

  final String userId;
  final String displayName;
  final bool isEditing;
  final DateTime joinedAt;

  factory PresenceUser.fromMap(Map<String, dynamic> map) => PresenceUser(
        userId: map['user_id'] as String,
        displayName: map['display_name'] as String,
        isEditing: map['is_editing'] as bool? ?? false,
        joinedAt: DateTime.parse(map['joined_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'display_name': displayName,
        'is_editing': isEditing,
        'joined_at': joinedAt.toIso8601String(),
      };

  PresenceUser copyWith({bool? isEditing}) => PresenceUser(
        userId: userId,
        displayName: displayName,
        isEditing: isEditing ?? this.isEditing,
        joinedAt: joinedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresenceUser &&
          userId == other.userId &&
          displayName == other.displayName &&
          isEditing == other.isEditing &&
          joinedAt == other.joinedAt;

  @override
  int get hashCode => Object.hash(userId, displayName, isEditing, joinedAt);
}
