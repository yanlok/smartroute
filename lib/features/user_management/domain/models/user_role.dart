enum UserRole {
  passenger,
  admin;

  static UserRole fromString(String? value) {
    if (value == 'admin') {
      return UserRole.admin;
    }
    return UserRole.passenger;
  }
}
