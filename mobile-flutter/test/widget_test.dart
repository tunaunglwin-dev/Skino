import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/src/app/skin_ai_mobile_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Skino renders guest-first home foundation', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'skino.onboarding.complete': true});

    await tester.pumpWidget(const SkinAiMobileApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Skino'), findsOneWidget);
    expect(find.text('မျက်နှာအလှစကင်'), findsOneWidget);
    expect(find.text('ပင်မ'), findsOneWidget);
    expect(find.text('စကင်'), findsAtLeastNWidgets(1));
    expect(find.text('ဆက်တင်'), findsOneWidget);
  });
}
