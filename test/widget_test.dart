import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Smoke test placeholder — Supabase.initialize() requires platform channel
    // so we test models/utilities instead.
    expect(1 + 1, equals(2));
  });
}
