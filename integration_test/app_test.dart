import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ibex_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End E2E Tests', () {
    testWidgets('Login as student, verify dashboard, and logout',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure we start at Login
      expect(find.text('Sign In'), findsOneWidget);

      // Enter student credentials (seeded previously)
      await tester.enterText(
          find.bySemanticsLabel('Email Address').first, 'student@ibex.com');
      await tester.enterText(
          find.bySemanticsLabel('Password').first, 'password123');
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should redirect to Student Dashboard
      expect(find.text('WELCOME BACK, Alice Student'), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify profile screen and sign out
      expect(find.text('Alice Student'), findsOneWidget);
      expect(find.text('student'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be back at login
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Login as teacher, verify dashboard, and logout',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(
          find.bySemanticsLabel('Email Address').first, 'teacher@ibex.com');
      await tester.enterText(
          find.bySemanticsLabel('Password').first, 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should redirect to Teacher Dashboard
      expect(find.text('Teacher Portal'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget); // Seeded class subject

      // Profile tab & sign out
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });
}
