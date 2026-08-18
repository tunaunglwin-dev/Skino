import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/src/app/skin_ai_mobile_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Skino requires AI face scan consent before onboarding finishes',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const SkinAiMobileApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Meet Your AI Skincare Bestie'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('AI Face Scan Consent'), findsOneWidget);
      expect(find.text('Agree and Start Skino'), findsOneWidget);

      await tester.tap(find.text('Agree and Start Skino'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('AI Face Scan Consent'), findsOneWidget);

      final consentText = find.textContaining('I understand Skino');
      await tester.ensureVisible(consentText);
      await tester.tap(consentText);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agree and Start Skino'));
      await tester.pumpAndSettle();

      expect(find.text('မျက်နှာအလှစကင်'), findsOneWidget);
    },
  );

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
