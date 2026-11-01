import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/chatbot.dart';

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.pumpWidget(
    const MaterialApp(home: CivilEngineerChatbotScreen()),
  );
  await tester.enterText(find.byType(TextField), question);
  await tester.tap(find.byIcon(Icons.send_rounded));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Tagalog question gets a Tagalog reply', (tester) async {
    await _ask(tester, 'Ano po ang pundasyon?');
    expect(find.textContaining('Ang pundasyon ang naglilipat'), findsOneWidget);
  });

  testWidgets('English question gets an English reply', (tester) async {
    await _ask(tester, 'What is a foundation?');
    expect(
      find.textContaining('A foundation transfers building loads'),
      findsOneWidget,
    );
  });

  testWidgets('Taglish about sqm replies in Tagalog', (tester) async {
    await _ask(tester, 'mag a ash ako abot sa sqm');
    expect(find.textContaining('Ang sukat ng lote'), findsOneWidget);
  });

  testWidgets('Taglish price question routes to cost in Tagalog',
      (tester) async {
    await _ask(tester, 'magkano ang cost ng 120 sqm?');
    expect(find.textContaining('Ang gastos ng pagtatayo'), findsOneWidget);
  });

  testWidgets('Off-topic Tagalog question is refused in Tagalog',
      (tester) async {
    await _ask(tester, 'pwede ba kita tanungin about sa schedule namin?');
    expect(
      find.textContaining('Sagot ko lang ang mga tanong tungkol sa pagtatayo'),
      findsOneWidget,
    );
  });

  testWidgets('Off-topic English question is refused in English',
      (tester) async {
    await _ask(tester, 'What is the best recipe for chicken adobo?');
    expect(
      find.textContaining('I only answer questions about building a house'),
      findsOneWidget,
    );
  });
}
