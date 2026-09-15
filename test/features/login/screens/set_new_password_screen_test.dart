import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/theme/app_theme.dart';
import 'package:smartroute/features/login/screens/set_new_password_screen.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';

class FakeResetAuthRepository implements AuthRepository {
  bool resetPasswordCalled = false;
  String? lastNewPassword;
  bool shouldThrow = false;

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resetPassword({required String newPassword}) async {
    resetPasswordCalled = true;
    lastNewPassword = newPassword;
    if (shouldThrow) {
      throw Exception('Update failed');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  group('SetNewPasswordScreen', () {
    late FakeResetAuthRepository repository;
    late AuthController controller;

    setUp(() {
      repository = FakeResetAuthRepository();
      controller = AuthController(authRepository: repository);
    });

    Widget createScreen({
      required VoidCallback onSuccess,
      required VoidCallback onCancel,
    }) {
      return MaterialApp(
        theme: AppTheme.light,
        home: SetNewPasswordScreen(
          authController: controller,
          onSuccess: onSuccess,
          onCancel: onCancel,
        ),
      );
    }

    testWidgets('renders all fields and labels', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen(onSuccess: () {}, onCancel: () {}));
      await tester.pump();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('NEW PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
      expect(find.text('Cancel and Return to Sign In'), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(onSuccess: () {}, onCancel: () {}));
      await tester.pump();

      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('All password fields are required.'), findsOneWidget);
      expect(repository.resetPasswordCalled, isFalse);
    });

    testWidgets('shows error when passwords do not match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createScreen(onSuccess: () {}, onCancel: () {}));
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'newpassword1');
      await tester.enterText(fields.at(1), 'newpassword2');

      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(find.text('New passwords do not match.'), findsOneWidget);
      expect(repository.resetPasswordCalled, isFalse);
    });

    testWidgets(
      'calls resetPassword when inputs are valid and triggers success',
      (WidgetTester tester) async {
        var successCalled = false;
        await tester.pumpWidget(
          createScreen(onSuccess: () => successCalled = true, onCancel: () {}),
        );
        await tester.pump();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'validpassword123');
        await tester.enterText(fields.at(1), 'validpassword123');

        await tester.tap(find.text('Update Password'));
        await tester.pump();

        expect(repository.resetPasswordCalled, isTrue);
        expect(repository.lastNewPassword, 'validpassword123');
        expect(
          find.text(
            'Password updated successfully. Please sign in with your new password.',
          ),
          findsOneWidget,
        );

        await tester.pump(const Duration(milliseconds: 1600));
        expect(successCalled, isTrue);
      },
    );

    testWidgets('cancel button invokes onCancel callback', (
      WidgetTester tester,
    ) async {
      var cancelCalled = false;
      await tester.pumpWidget(
        createScreen(onSuccess: () {}, onCancel: () => cancelCalled = true),
      );
      await tester.pump();

      await tester.tap(find.text('Cancel and Return to Sign In'));
      await tester.pump();

      expect(cancelCalled, isTrue);
    });
  });
}
