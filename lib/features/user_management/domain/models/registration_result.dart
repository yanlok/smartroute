import 'app_user.dart';

class RegistrationResult {
  final AppUser user;
  final bool hasActiveSession;

  const RegistrationResult({
    required this.user,
    required this.hasActiveSession,
  });

  bool get requiresEmailConfirmation => !hasActiveSession;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegistrationResult &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          hasActiveSession == other.hasActiveSession;

  @override
  int get hashCode => user.hashCode ^ hasActiveSession.hashCode;
}
