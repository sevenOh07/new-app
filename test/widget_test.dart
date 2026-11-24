import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiikawa_app/main.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Doodle_Head')
    ..addFont(rootBundle.load('assets/fonts/Doodle_Head.ttf'));
  await loader.load();
}

void main() {
  testWidgets('shows the loading screen then the home screen', (tester) async {
    await _loadFonts();
    await tester.pumpWidget(const MyApp());

    expect(find.text('Loading....'), findsOneWidget);
    expect(find.text("There's nothing here..."), findsNothing);

    // The splash hands over to the home screen on its own.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Loading....'), findsNothing);
    expect(find.text("There's nothing here..."), findsOneWidget);
  });
}
