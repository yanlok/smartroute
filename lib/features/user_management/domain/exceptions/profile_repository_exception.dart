class ProfileRepositoryException implements Exception {
  final String message;

  const ProfileRepositoryException(this.message);

  @override
  String toString() => 'ProfileRepositoryException: $message';
}
