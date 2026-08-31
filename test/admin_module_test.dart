import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/admin/admin_constants.dart';
import 'package:smartroute/core/theme/app_theme.dart';
import 'package:smartroute/features/login/screens/login_screen.dart';
import 'package:smartroute/main.dart';

void main() {
  testWidgets('admin can enter portal, validate, sign in, and log out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SmartRouteApp());
    await tester.pump();

    final portalEntry = find.byKey(const Key('open-admin-portal'));
    await tester.ensureVisible(portalEntry);
    await tester.pump();
    await tester.tap(portalEntry);
    await tester.pump();

    expect(find.text(AdminConstants.portalName), findsOneWidget);

    final loginButton = find.byKey(const Key('admin-login-button'));
    await tester.ensureVisible(loginButton);
    await tester.pump();
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Enter the admin email address.'), findsOneWidget);
    expect(find.text('Enter the admin password.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('admin-email-field')),
      AdminConstants.demoEmail,
    );
    await tester.enterText(
      find.byKey(const Key('admin-password-field')),
      AdminConstants.demoPassword,
    );
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Welcome, Administrator'), findsOneWidget);
    expect(find.text('Admin workspace ready'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump();
    final logoutButton = find.byKey(const Key('admin-logout-button'));
    await tester.ensureVisible(logoutButton);
    await tester.pump();
    await tester.tap(logoutButton);
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-admin-logout')));
    await tester.pump();

    expect(find.byKey(const Key('open-admin-portal')), findsOneWidget);
    expect(find.text('Sign In to SmartRoute'), findsOneWidget);
  });

  testWidgets('normal passenger login remains available', (tester) async {
    var passengerLoggedIn = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(
          onLogin: () => passengerLoggedIn = true,
          onAdminPortal: () {},
        ),
      ),
    );
    await tester.pump();

    final passengerLogin = find.text('Sign In to SmartRoute');
    await tester.ensureVisible(passengerLogin);
    await tester.pump();
    await tester.tap(passengerLogin);
    await tester.pump();

    expect(passengerLoggedIn, isTrue);
  });
}
