import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/components/signin_signup/sign_up.dart';

Widget createWidgetUnderTest() {
  return MaterialApp(
    home: SignUpPage(),
    routes: {
      '/sign_in': (context) => const Scaffold(body: Center(child: Text('Sign In Page'))),
      '/account_setup': (context) => const Scaffold(body: Center(child: Text('Account Setup Page'))),
      '/home': (context) => const Scaffold(body: Center(child: Text('Home Page'))),
    },
  );
}

void main() {
  testWidgets(r'Should display sign up UI correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text(r"Sign Up"), findsOneWidget);
    expect(find.widgetWithText(TextField, r"Enter your email"), findsOneWidget);
    expect(find.widgetWithText(TextField, r"Enter your password"), findsOneWidget);
    expect(find.widgetWithText(TextField, r"Confirm password"), findsOneWidget);
    expect(find.text(r"Continue"), findsOneWidget);
  });

  testWidgets(r'Should show error message when email is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Leave email empty, fill other fields for bypassing subsequent validations.
    await tester.enterText(
        find.widgetWithText(TextField, r"Enter your password"), "password123"
    );
    await tester.enterText(
        find.widgetWithText(TextField, r"Confirm password"), "password123"
    );

    final continueButton = find.text(r"Continue");
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(r"Please enter an email address"), findsOneWidget);
  });

  testWidgets(r'Should show error message when password is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Fill email and leave password empty
    await tester.enterText(find.widgetWithText(TextField, r"Enter your email"), "test@example.com");
    await tester.enterText(find.widgetWithText(TextField, r"Confirm password"), "password123");

    final continueButton = find.text(r"Continue");
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(r"Please enter a password"), findsOneWidget);
  });

  testWidgets(r'Should show error message when confirm password is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Fill email and password but leave confirm password empty
    await tester.enterText(find.widgetWithText(TextField, r"Enter your email"), "test@example.com");
    await tester.enterText(find.widgetWithText(TextField, r"Enter your password"), "password123");

    final continueButton = find.text(r"Continue");
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(r"Please confirm your password"), findsOneWidget);
  });

  testWidgets(r'Should show error message when passwords do not match', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Fill email, password and a different confirm password.
    await tester.enterText(find.widgetWithText(TextField, r"Enter your email"), "test@example.com");
    await tester.enterText(find.widgetWithText(TextField, r"Enter your password"), "password123");
    await tester.enterText(find.widgetWithText(TextField, r"Confirm password"), "password321");

    final continueButton = find.text(r"Continue");
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(r"Passwords do not match"), findsOneWidget);
  });

  testWidgets(r'Should toggle password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final passwordField = find.widgetWithText(TextField, r"Enter your password");
    var textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, isTrue);

    final toggleIcon = find.descendant(
      of: passwordField,
      matching: find.byIcon(Icons.visibility_off),
    );
    await tester.tap(toggleIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, isFalse);
  });

  testWidgets(r'Should toggle password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Locate password TextField widget.
    final passwordField = find.widgetWithText(TextField, r"Enter your password");
    var textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, isTrue);

    // Tap on suffixIcon button for password toggle.
    final toggleIcon = find.descendant(
      of: passwordField,
      matching: find.byIcon(Icons.visibility_off),
    );
    await tester.tap(toggleIcon);
    await tester.pump();

    textField = tester.widget<TextField>(passwordField);
    expect(textField.obscureText, isFalse);
  });
}