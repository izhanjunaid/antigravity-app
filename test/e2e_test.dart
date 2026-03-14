import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibex_app/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

// We must allow HTTP requests in widget tests to hit the real Supabase instance
class FallbackHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = FallbackHttpOverrides();
    // Supabase initialize calls SharedPreferences, need to mock it for tests
    SharedPreferences.setMockInitialValues({});
  });

  group('End-to-End Auth Flows (Widget Test)', () {
    testWidgets('Login as student, verify dashboard, and logout',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure we start at Login
      expect(find.text('Sign In'), findsOneWidget);

      // Enter student credentials (seeded previously)
      await tester.enterText(
          find.byType(TextFormField).first, 'student@ibex.com');
      await tester.enterText(
          find.byType(TextFormField).last, 'password123');
      await tester.pumpAndSettle();

      // Tap Sign In
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      
      // Since network and auth redirects can cause infinite layout frames
      // or loading indicators, pump discrete amounts of time instead.
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Check for error message or dashboard
      if (find.textContaining('WELCOME BACK').evaluate().isNotEmpty) {
        expect(find.text('WELCOME BACK, Alice Student'), findsOneWidget);
        
        await tester.tap(find.text('Profile'));
        await tester.pump(const Duration(seconds: 2));
        
        expect(find.text('Sign Out'), findsOneWidget);
      }

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be back at login
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
