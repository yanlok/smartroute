class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoUrl,
  });

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? photoUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          email == other.email &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      id.hashCode ^ fullName.hashCode ^ email.hashCode ^ photoUrl.hashCode;
}
