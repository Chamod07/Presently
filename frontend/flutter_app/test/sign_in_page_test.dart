import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/components/signin_signup/sign_in.dart';

Widget createWidgetUnderTest() {
  return MaterialApp(
    home: const SignInPage(),
    routes: {
      '/sign_in': (context) =>
          const Scaffold(body: Center(child: Text('Sign In Page'))),
      '/home': (context) =>
          const Scaffold(body: Center(child: Text('Home Page'))),
      '/sign_up': (context) =>
          const Scaffold(body: Center(child: Text('Sign Up Page'))),
    },
  );
}

void main() {
  testWidgets(r'Should display sign in UI correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text(r"Sign In"), findsOneWidget);
    expect(find.widgetWithText(TextField, r"Enter your email"), findsOneWidget);
    expect(find.widgetWithText(TextField, r"Enter your password"), findsOneWidget);
    expect(find.text(r"Continue"), findsOneWidget);
    expect(find.text(r"Continue with Google"), findsOneWidget);
  });

  testWidgets(r'Should show error message when email is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Fill password but leave email empty.
    await tester.enterText(find.widgetWithText(TextField, r"Enter your password"), "password123");

    final continueButton = find.text(r"Continue");
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(r"Please enter your email"), findsOneWidget);
  });

  testWidgets(r'Should show error message when password is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Fill email but leave password empty.
    await tester.enterText(find.widgetWithText(TextField, r"Enter your email"), "test@example.com");

    final continueButton = find.text(r"Continue");
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(r"Please enter your password"), findsOneWidget);
  });

  testWidgets(r'Should toggle password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final passwordFieldFinder = find.widgetWithText(TextField, r"Enter your password");
    final passwordTextField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordTextField.obscureText, isTrue);

    // Locate the toggle IconButton by finding descendant icon.
    final toggleIconFinder = find.descendant(
      of: passwordFieldFinder,
      matching: find.byType(IconButton),
    );
    await tester.tap(toggleIconFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    final updatedPasswordField = tester.widget<TextField>(passwordFieldFinder);
    expect(updatedPasswordField.obscureText, isFalse);
  });

}