import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/login/screens/login_screen.dart';
import 'package:smartroute/features/login/screens/set_new_password_screen.dart';
import 'package:smartroute/features/planner/application/planner_controller.dart';
import 'package:smartroute/features/tracking/application/tracking_controller.dart';
import 'package:smartroute/features/tracking/domain/repositories/line_directory_repository.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/features/user_management/application/auth_controller.dart';
import 'package:smartroute/features/user_management/application/profile_controller.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/application/user_role_controller.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/registration_result.dart';
import 'package:smartroute/features/user_management/domain/models/user_role.dart';
import 'package:smartroute/features/user_management/domain/repositories/auth_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/avatar_storage_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/profile_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/user_role_repository.dart';
import 'package:smartroute/main.dart';
import 'package:smartroute/shared/contracts/location_repository.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {
  bool signOutCalled = false;
  bool resetPasswordCalled = false;
  String? lastNewPassword;

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return const AppUser(id: 'u1', fullName: 'User', email: 'user@test.com');
  }

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return const RegistrationResult(
      user: AppUser(id: 'u1', fullName: 'User', email: 'user@test.com'),
      hasActiveSession: true,
    );
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    resetPasswordCalled = true;
    lastNewPassword = newPassword;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    return const AppUser(id: 'u1', fullName: 'Google', email: 'g@test.com');
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class _FakeUserRoleRepo extends Fake implements UserRoleRepository {
  int getRoleCallCount = 0;

  @override
  Future<UserRole> getRole(String userId) async {
    getRoleCallCount++;
    return UserRole.passenger;
  }
}

class _FakeProfileRepo extends Fake implements ProfileRepository {}

class _FakeAvatarRepo extends Fake implements AvatarStorageRepository {}

class _FakeSavedRepo extends Fake implements SavedJourneyRepository {}

class _FakeNoticeRepo extends Fake implements NoticeRepository {}

class _FakeTransitRepo extends Fake implements TransitNetworkRepository {}

class _FakeLocationRepo extends Fake implements LocationRepository {}

class _FakeTrackingRepo extends Fake implements TrackingRepository {}

class _FakeDirectoryRepo extends Fake implements LineDirectoryRepository {}

void main() {
  group('AppShell password recovery lifecycle', () {
    late _FakeAuthRepo authRepo;
    late _FakeUserRoleRepo roleRepo;
    late AuthController authController;
    late UserRoleController userRoleController;
    late ProfileController profileController;
    late SavedJourneyController savedJourneys;
    late NoticeController noticeController;
    late PlannerController plannerController;
    late TransitNetworkController transitController;
    late TrackingController trackingController;

    setUp(() {
      authRepo = _FakeAuthRepo();
      roleRepo = _FakeUserRoleRepo();
      authController = AuthController(authRepository: authRepo);
      userRoleController = UserRoleController(repository: roleRepo);
      profileController = ProfileController(
        profileRepository: _FakeProfileRepo(),
        avatarStorageRepository: _FakeAvatarRepo(),
      );
      savedJourneys = SavedJourneyController(repository: _FakeSavedRepo());
      noticeController = NoticeController(repository: _FakeNoticeRepo());
      plannerController = PlannerController(
        networkRepository: _FakeTransitRepo(),
        locationRepository: _FakeLocationRepo(),
      );
      transitController = TransitNetworkController(
        repository: _FakeTransitRepo(),
      );
      trackingController = TrackingController(
        trackingRepository: _FakeTrackingRepo(),
        directoryRepository: _FakeDirectoryRepo(),
      );
    });

    Widget createTestApp() {
      return MaterialApp(
        home: AppShell(
          authController: authController,
          userRoleController: userRoleController,
          profileController: profileController,
          savedJourneys: savedJourneys,
          noticeController: noticeController,
          plannerController: plannerController,
          transitController: transitController,
          trackingController: trackingController,
        ),
      );
    }

    testWidgets(
      'renders SetNewPasswordScreen when isPasswordRecovery is true and does not invoke role resolution',
      (tester) async {
        authController.setPasswordRecovery(true);

        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byType(SetNewPasswordScreen), findsOneWidget);
        expect(find.text('Set New Password'), findsOneWidget);
        expect(roleRepo.getRoleCallCount, 0);
      },
    );

    testWidgets(
      'successful reset password clears recovery, signs out session, resets role, and returns to LoginScreen',
      (tester) async {
        authController.setPasswordRecovery(true);

        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byType(SetNewPasswordScreen), findsOneWidget);

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'newpassword123');
        await tester.enterText(textFields.at(1), 'newpassword123');

        await tester.tap(find.text('Update Password'));
        await tester.pump();

        expect(authRepo.resetPasswordCalled, isTrue);
        expect(authRepo.signOutCalled, isTrue);
        expect(authController.isPasswordRecovery, isFalse);
        expect(authController.isAuthenticated, isFalse);

        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(roleRepo.getRoleCallCount, 0);
      },
    );

    testWidgets(
      'cancelling recovery signs out session and navigates directly to LoginScreen',
      (tester) async {
        authController.setPasswordRecovery(true);

        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byType(SetNewPasswordScreen), findsOneWidget);

        final cancelButton = find.text('Cancel and Return to Sign In');
        await tester.ensureVisible(cancelButton);
        await tester.pump();
        await tester.tap(cancelButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(authRepo.signOutCalled, isTrue);
        expect(authController.isPasswordRecovery, isFalse);
        expect(authController.isAuthenticated, isFalse);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(roleRepo.getRoleCallCount, 0);
      },
    );
  });
}
