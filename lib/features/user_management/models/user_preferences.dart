class UserPreferences {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final String language;

  const UserPreferences({
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.language = 'English (Malaysia)',
  });

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
    String? language,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          notificationsEnabled == other.notificationsEnabled &&
          locationEnabled == other.locationEnabled &&
          language == other.language;

  @override
  int get hashCode =>
      notificationsEnabled.hashCode ^
      locationEnabled.hashCode ^
      language.hashCode;
}
