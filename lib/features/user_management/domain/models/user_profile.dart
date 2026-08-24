class UserProfile {
  final String id;
  final String fullName;
  final String? photoUrl;

  const UserProfile({required this.id, required this.fullName, this.photoUrl});

  UserProfile copyWith({String? id, String? fullName, String? photoUrl}) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      id.hashCode ^ fullName.hashCode ^ (photoUrl?.hashCode ?? 0);
}
