import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/application/user_role_controller.dart';
import 'package:smartroute/features/user_management/domain/models/user_role.dart';
import 'package:smartroute/features/user_management/domain/repositories/user_role_repository.dart';

class FakeUserRoleRepository implements UserRoleRepository {
  UserRole roleToReturn = UserRole.passenger;
  bool shouldThrow = false;
  int getRoleCalls = 0;
  String? lastUserId;

  @override
  Future<UserRole> getRole(String userId) async {
    getRoleCalls++;
    lastUserId = userId;
    if (shouldThrow) {
      throw Exception('Database error');
    }
    return roleToReturn;
  }
}

void main() {
  group('UserRole enum', () {
    test('fromString parses admin correctly', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('fromString defaults to passenger for non-admin strings or null', () {
      expect(UserRole.fromString('passenger'), UserRole.passenger);
      expect(UserRole.fromString(null), UserRole.passenger);
      expect(UserRole.fromString(''), UserRole.passenger);
      expect(UserRole.fromString('other'), UserRole.passenger);
    });
  });

  group('UserRoleController', () {
    late FakeUserRoleRepository repository;
    late UserRoleController controller;

    setUp(() {
      repository = FakeUserRoleRepository();
      controller = UserRoleController(repository: repository);
    });

    test('initial state has default passenger role and is not resolved', () {
      expect(controller.role, UserRole.passenger);
      expect(controller.isAdmin, isFalse);
      expect(controller.isResolved, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('resolveRole resolves admin role successfully', () async {
      repository.roleToReturn = UserRole.admin;

      final role = await controller.resolveRole('admin-123');

      expect(role, UserRole.admin);
      expect(controller.role, UserRole.admin);
      expect(controller.isAdmin, isTrue);
      expect(controller.isResolved, isTrue);
      expect(controller.isLoading, isFalse);
      expect(repository.getRoleCalls, 1);
      expect(repository.lastUserId, 'admin-123');
    });

    test('resolveRole resolves passenger role successfully', () async {
      repository.roleToReturn = UserRole.passenger;

      final role = await controller.resolveRole('user-456');

      expect(role, UserRole.passenger);
      expect(controller.role, UserRole.passenger);
      expect(controller.isAdmin, isFalse);
      expect(controller.isResolved, isTrue);
      expect(controller.isLoading, isFalse);
      expect(repository.getRoleCalls, 1);
      expect(repository.lastUserId, 'user-456');
    });

    test(
      'resolveRole sets error and does not resolve on repository failure',
      () async {
        repository.shouldThrow = true;

        final role = await controller.resolveRole('error-user');

        expect(role, isNull);
        expect(controller.isAdmin, isFalse);
        expect(controller.isResolved, isFalse);
        expect(controller.hasError, isTrue);
        expect(
          controller.errorMessage,
          'Unable to verify account access. Please try again.',
        );
        expect(controller.isLoading, isFalse);
      },
    );

    test('reset clears role state and flags', () async {
      repository.roleToReturn = UserRole.admin;
      await controller.resolveRole('admin-123');
      expect(controller.isResolved, isTrue);

      controller.reset();

      expect(controller.isResolved, isFalse);
      expect(controller.role, UserRole.passenger);
      expect(controller.isAdmin, isFalse);
    });
  });
}
