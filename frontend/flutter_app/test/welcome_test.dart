import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/components/onboarding/welcome.dart';

void main() {
  // Helper widget that sets up the MaterialApp with routes.
  Widget createTestWidget() {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/sign_in': (context) => const Scaffold(
              body: Center(child: Text('Sign In Page')),
            ),
      },
    );
  }

  testWidgets('WelcomePage displays title and navigates on button tap', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify that the title is displayed.
    expect(find.text('Presently'), findsOneWidget);
    // Verify that the button label is displayed.
    expect(find.text('Let\'s Get Started!'), findsOneWidget);

    // Tap the button.
    await tester.tap(find.text('Let\'s Get Started!'));
    await tester.pumpAndSettle();

    // Verify that navigation to the sign-in page occurred.
    expect(find.text('Sign In Page'), findsOneWidget);
  });
}