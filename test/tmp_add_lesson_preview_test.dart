import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiikawa_app/main.dart';

void main() {
  testWidgets('add lesson preview', (tester) async {
    final previewKey = GlobalKey();
    final loader = FontLoader('Doodle_Head')
      ..addFont(rootBundle.load('assets/fonts/Doodle_Head.ttf'));
    await loader.load();

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(key: previewKey, child: const MyApp()),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Create the folder that the lesson will go into.
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_folder_option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('folder_name_field')),
      'Math Lessons',
    );
    await tester.tap(find.byKey(const Key('confirm_folder_button')));
    await tester.pumpAndSettle();

    // Open the clipboard form and fill it in.
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_lessons_option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('lesson_front_field')),
      'What is 2 + 2?',
    );
    await tester.enterText(
      find.byKey(const Key('lesson_back_field')),
      'Four!',
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold).last);
      for (final asset in const [
        'assets/images/grassy_background.png',
        'assets/images/clipboard2_notebook.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(previewKey),
      matchesGoldenFile('add_lesson_preview.png'),
    );
  });
}
