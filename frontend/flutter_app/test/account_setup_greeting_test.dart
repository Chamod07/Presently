import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/components/onboarding/account_setup_greeting.dart';

Widget createTestWidget({required Map<String, String> args}) {
  return MaterialApp(
    initialRoute: '/',
    onGenerateRoute: (RouteSettings settings) {
      if (settings.name == '/') {
        return MaterialPageRoute(
          builder: (_) => const AccountSetupGreeting(),
          settings: RouteSettings(arguments: args),
        );
      }
      if (settings.name == '/home') {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Home')),
            body: Center(child: Text('Home')),
          ),
        );
      }
      return null;
    },
  );
}

void main() {
  testWidgets('AccountSetupGreeting displays greeting and navigates to home on button tap', (WidgetTester tester) async {
    // Provide a firstName argument.
    final args = <String, String>{'firstName': 'Test'};

    await tester.pumpWidget(createTestWidget(args: args));
    await tester.pumpAndSettle();

    // Verify that the greeting text displays the passed first name.
    expect(find.text('Hello Test!'), findsOneWidget);
    expect(find.text('Setup Complete'), findsOneWidget);

    // Verify that the navigation button exists.
    expect(find.text("Let's Begin!"), findsOneWidget);

    // Tap the "Let's Begin!" button.
    await tester.tap(find.text("Let's Begin!"));
    await tester.pumpAndSettle();

    // Verify that the AppBar contains the Home title.
    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);
  });
}