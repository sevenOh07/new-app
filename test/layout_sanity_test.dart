import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiikawa_app/screens/flashcard.dart';
import 'package:chiikawa_app/screens/quiz.dart';
import 'package:chiikawa_app/screens/search_screen.dart';
import 'package:chiikawa_app/main.dart';
import 'package:chiikawa_app/models/lesson.dart';
import 'package:chiikawa_app/models/study_folder.dart';

/// Widget tests draw text with a placeholder font unless the real one is
/// loaded, which would make layout measurements meaningless. Load Doodle_Head
/// so the home screen is measured the way it renders on a device.
Future<void> _loadFonts() async {
  final loader = FontLoader('Doodle_Head')
    ..addFont(rootBundle.load('assets/fonts/Doodle_Head.ttf'));
  await loader.load();
}

/// Boots the app and waits for the loading screen to hand over to the home
/// screen.
Future<void> pumpApp(WidgetTester tester) async {
  await _loadFonts();
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

/// Opens the add panel, names a folder, and confirms it.
Future<void> createFolder(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('add_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('create_folder_option')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('folder_name_field')), name);
  await tester.tap(find.byKey(const Key('confirm_folder_button')));
  await tester.pumpAndSettle();
}

/// Opens the clipboard form from the add panel.
Future<void> openAddLesson(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('add_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add_lessons_option')));
  await tester.pumpAndSettle();
}

/// Saves a text-only lesson into the first folder.
Future<void> addLesson(
  WidgetTester tester, {
  required String front,
  required String back,
}) async {
  await openAddLesson(tester);
  await tester.enterText(find.byKey(const Key('lesson_front_field')), front);
  await tester.enterText(find.byKey(const Key('lesson_back_field')), back);
  await tester.tap(find.byKey(const Key('lesson_save_button')));
  await tester.pumpAndSettle();

  // Let the confirmation snackbar clear so it does not cover the plus button
  // when the next lesson is added.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// Opens the study-mode panel for a folder.
Future<void> openFolderOptions(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Picks the flashcard mode for a folder.
Future<void> openFlashcards(WidgetTester tester, String name) async {
  await openFolderOptions(tester, name);
  await tester.tap(find.byKey(const Key('flashcards_option')));
  await tester.pumpAndSettle();
}

/// Picks the quiz mode for a folder.
Future<void> openQuiz(WidgetTester tester, String name) async {
  await openFolderOptions(tester, name);
  await tester.tap(find.byKey(const Key('quiz_option')));
  await tester.pumpAndSettle();
}

void main() {
  const sizes = [
    Size(360, 640),
    Size(400, 800),
    Size(430, 932),
    Size(800, 600),
    Size(1400, 800),
    Size(1920, 1080),
    Size(320, 480),
    Size(1200, 300),
  ];

  for (final size in sizes) {
    testWidgets('no overflow at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester);
      expect(tester.takeException(), isNull);

      final chiikawa = find.image(
        const AssetImage('assets/images/chiikawa_confused.png'),
      );
      expect(chiikawa, findsOneWidget);
      final rect = tester.getRect(chiikawa);
      expect(rect.width, closeTo(rect.height, 0.01));
      expect(rect.width, greaterThan(0));

      final grass = tester.getRect(
        find.image(const AssetImage('assets/images/grassy_background.png')),
      );

      // The visible green edge of the grass (162/1537 into the PNG) sits on
      // Chiikawa's visible feet (602/736 into her PNG).
      final greenTop = grass.top + grass.height * (162 / 1537);
      final feetY = rect.top + rect.height * (602 / 736);
      expect(greenTop, closeTo(feetY, 0.01));

      // ...and the grass still covers everything below the line.
      expect(grass.bottom, greaterThanOrEqualTo(size.height));

      // The plus button sits fully inside the bottom-right corner.
      final button = tester.getRect(find.byKey(const Key('add_button')));
      expect(button.right, lessThanOrEqualTo(size.width));
      expect(button.bottom, lessThanOrEqualTo(size.height));
      expect(button.right, greaterThan(size.width * 0.7));
      expect(button.bottom, greaterThan(size.height * 0.7));

      // The menu button sits fully inside the top-left corner.
      final menu = tester.getRect(find.byKey(const Key('menu_button')));
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(menu.top, greaterThanOrEqualTo(0));
      expect(menu.left, lessThan(size.width * 0.3));
      expect(menu.top, lessThan(size.height * 0.3));

      // The search button sits fully inside the top-right corner.
      final search = tester.getRect(find.byKey(const Key('search_button')));
      expect(search.right, lessThanOrEqualTo(size.width));
      expect(search.top, greaterThanOrEqualTo(0));
      expect(search.right, greaterThan(size.width * 0.7));
      expect(search.top, lessThan(size.height * 0.3));

      // The message stays fully on screen and sits above Chiikawa.
      final message = tester.getRect(find.text("There's nothing here..."));
      expect(message.top, greaterThanOrEqualTo(0));
      expect(message.bottom, lessThan(rect.top));
      expect(message.left, greaterThanOrEqualTo(0));
      expect(message.right, lessThanOrEqualTo(size.width));

      // ...and it never collides with the corner buttons.
      expect(message.overlaps(menu), isFalse);
      expect(message.overlaps(search), isFalse);
    });
  }

  testWidgets('the plus button opens the two add options', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();

    expect(find.text('Create Folder'), findsOneWidget);
    expect(find.text('Add Lessons'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The choices stay fully on screen.
    final create = tester.getRect(
      find.byKey(const Key('create_folder_option')),
    );
    final lessons = tester.getRect(find.byKey(const Key('add_lessons_option')));
    expect(create.top, greaterThanOrEqualTo(0));
    expect(lessons.bottom, lessThanOrEqualTo(800));
    expect(create.bottom, lessThan(lessons.top));
  });

  testWidgets('Create Folder asks for a name and adds the folder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_folder_option')));
    await tester.pumpAndSettle();

    // The panel closes and the naming dialog opens.
    expect(find.byKey(const Key('folder_name_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('folder_name_field')),
      'Math Lessons',
    );
    await tester.tap(find.byKey(const Key('confirm_folder_button')));
    await tester.pumpAndSettle();

    // The folder replaces the empty state.
    expect(find.text('Math Lessons'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/folder_chiikawa.png')),
      findsOneWidget,
    );
    expect(find.text("There's nothing here..."), findsNothing);
    expect(
      find.image(const AssetImage('assets/images/chiikawa_confused.png')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Create Folder uses the prefilled name', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_folder_option')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_folder_button')));
    await tester.pumpAndSettle();

    expect(find.text('New Folder'), findsOneWidget);
  });

  testWidgets('Cancel leaves the home screen empty', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create_folder_option')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel_folder_button')));
    await tester.pumpAndSettle();

    expect(find.text("There's nothing here..."), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/folder_chiikawa.png')),
      findsNothing,
    );
  });

  testWidgets('folders stack in the order they are created', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await createFolder(tester, 'Studies Folder');

    expect(
      find.image(const AssetImage('assets/images/folder_chiikawa.png')),
      findsNWidgets(2),
    );

    final math = tester.getRect(find.text('Math Lessons'));
    final studies = tester.getRect(find.text('Studies Folder'));
    expect(studies.top, greaterThan(math.top));
  });

  testWidgets('a folder with no lessons says so', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');

    await tester.tap(find.text('Math Lessons'));
    await tester.pump();

    expect(find.text('This folder has no lessons yet!'), findsOneWidget);
    expect(find.byKey(const Key('flashcard_screen')), findsNothing);
  });

  testWidgets('a folder offers flashcards and a quiz', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'What is 2 + 2?', back: '4');

    await openFolderOptions(tester, 'Math Lessons');

    expect(find.byKey(const Key('flashcards_option')), findsOneWidget);
    expect(find.byKey(const Key('quiz_option')), findsOneWidget);
    expect(find.text('Flash Cards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quiz asks for at least two lessons', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'What is 2 + 2?', back: '4');

    await openFolderOptions(tester, 'Math Lessons');
    await tester.tap(find.byKey(const Key('quiz_option')));
    await tester.pumpAndSettle();

    expect(
      find.text('Add at least 2 lessons to start a quiz!'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('quiz_screen')), findsNothing);
  });

  testWidgets('the quiz scores a correct answer', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');
    await addLesson(tester, front: 'Front two', back: 'Back two');

    await openQuiz(tester, 'Math Lessons');

    expect(find.byKey(const Key('quiz_screen')), findsOneWidget);
    expect(find.byKey(const Key('quiz_question_card')), findsOneWidget);
    expect(find.text('Back one'), findsOneWidget);
    expect(find.text('Back two'), findsOneWidget);
    expect(find.text('Choose the correct answer'), findsOneWidget);

    // The question order is shuffled, so ask the screen which card is up.
    final firstIsOne = find.text('Front one').evaluate().isNotEmpty;
    final firstCorrect = firstIsOne ? 'Back one' : 'Back two';

    await tester.tap(find.text(firstCorrect));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_next_button')), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz_next_button')));
    await tester.pumpAndSettle();

    final secondCorrect = firstIsOne ? 'Back two' : 'Back one';
    await tester.tap(find.text(secondCorrect));
    await tester.pumpAndSettle();

    expect(find.text('See results'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quiz_next_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_result')), findsOneWidget);
    expect(find.text('Good job! You passed!'), findsOneWidget);
    expect(find.byKey(const Key('quiz_result_happy')), findsOneWidget);
    expect(find.text('You got 2 out of 2 right.'), findsOneWidget);
    expect(find.byKey(const Key('quiz_done_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quiz reports wrong answers', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');
    await addLesson(tester, front: 'Front two', back: 'Back two');

    await openQuiz(tester, 'Math Lessons');

    final firstIsOne = find.text('Front one').evaluate().isNotEmpty;
    final firstWrong = firstIsOne ? 'Back two' : 'Back one';

    await tester.tap(find.text(firstWrong));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz_next_button')));
    await tester.pumpAndSettle();

    final secondWrong = firstIsOne ? 'Back one' : 'Back two';
    await tester.tap(find.text(secondWrong));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz_next_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_result')), findsOneWidget);
    expect(find.text("It's not the end! try again!"), findsOneWidget);
    expect(find.byKey(const Key('quiz_result_sad')), findsOneWidget);
    expect(find.text('You got 0 out of 2 right.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quiz fits every screen size', (tester) async {
    await _loadFonts();

    const lessons = [
      Lesson(frontText: 'Front one', backText: 'Back one'),
      Lesson(frontText: 'Front two', backText: 'Back two'),
      Lesson(frontText: 'Front three', backText: 'Back three'),
      Lesson(frontText: 'Front four', backText: 'Back four'),
    ];
    const frontToBack = {
      'Front one': 'Back one',
      'Front two': 'Back two',
      'Front three': 'Back three',
      'Front four': 'Back four',
    };

    const sizes = [
      Size(320, 480),
      Size(400, 800),
      Size(800, 600),
      Size(1400, 800),
      Size(1200, 300),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(
            key: ValueKey(size),
            folderName: 'Math Lessons',
            lessons: lessons,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(const Key('quiz_question_card')));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(size.width));
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.bottom, lessThanOrEqualTo(size.height));

      for (final back in frontToBack.values) {
        final option = tester.getRect(find.text(back));
        expect(option.left, greaterThanOrEqualTo(0));
        expect(option.right, lessThanOrEqualTo(size.width));
        expect(option.top, greaterThanOrEqualTo(card.bottom));
        expect(option.bottom, lessThanOrEqualTo(size.height));
      }

      var correctBack = '';
      for (final entry in frontToBack.entries) {
        if (find.text(entry.key).evaluate().isNotEmpty) {
          correctBack = entry.value;
          break;
        }
      }
      expect(correctBack, isNotEmpty);

      await tester.tap(find.text(correctBack));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final next = tester.getRect(find.byKey(const Key('quiz_next_button')));
      expect(next.top, greaterThanOrEqualTo(card.bottom));
      expect(next.bottom, lessThanOrEqualTo(size.height));
      expect(next.left, greaterThanOrEqualTo(0));
      expect(next.right, lessThanOrEqualTo(size.width));
    }

    tester.view.reset();
  });

  testWidgets('tapping a folder opens its flashcards and flips them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'What is 2 + 2?', back: '4');

    await openFlashcards(tester, 'Math Lessons');

    expect(find.byKey(const Key('flashcard_screen')), findsOneWidget);
    expect(find.text('What is 2 + 2?'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('Tap the card to see the back'), findsOneWidget);
    expect(find.byKey(const Key('good_button')), findsNothing);
    expect(
      find.image(const AssetImage('assets/images/front_green.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/images/back_red.png')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('flashcard_card')));
    await tester.pumpAndSettle();

    expect(find.text('What is 2 + 2?'), findsNothing);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Review again'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/front_green.png')),
      findsNothing,
    );
    expect(
      find.image(const AssetImage('assets/images/back_red.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Good moves straight on to the next card', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');
    await addLesson(tester, front: 'Front two', back: 'Back two');

    await openFlashcards(tester, 'Math Lessons');
    expect(find.text('Front one'), findsOneWidget);

    await tester.tap(find.byKey(const Key('flashcard_card')));
    await tester.pumpAndSettle();
    expect(find.text('Back one'), findsOneWidget);

    await tester.tap(find.byKey(const Key('good_button')));
    await tester.pumpAndSettle();

    expect(find.text('Front two'), findsOneWidget);
    expect(find.text('Back one'), findsNothing);
    expect(find.text('Tap the card to see the back'), findsOneWidget);

    await tester.tap(find.byKey(const Key('flashcard_card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('good_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('flashcard_done')), findsOneWidget);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('Back to folders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Review again sends the card to the end of the queue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');
    await addLesson(tester, front: 'Front two', back: 'Back two');

    await openFlashcards(tester, 'Math Lessons');

    // Review the first card again: the second card comes up next.
    await tester.tap(find.byKey(const Key('flashcard_card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review_again_button')));
    await tester.pumpAndSettle();

    expect(find.text('Front two'), findsOneWidget);
    expect(find.text('Front one'), findsNothing);

    // Mark the second card good: the first card returns at the end.
    await tester.tap(find.byKey(const Key('flashcard_card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('good_button')));
    await tester.pumpAndSettle();

    expect(find.text('Front one'), findsOneWidget);
    expect(find.text('Back two'), findsNothing);

    await tester.tap(find.byKey(const Key('flashcard_card')));
    await tester.pumpAndSettle();
    expect(find.text('Back one'), findsOneWidget);

    await tester.tap(find.byKey(const Key('good_button')));
    await tester.pumpAndSettle();
    expect(find.text('All done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the flashcard fits every screen size', (tester) async {
    await _loadFonts();

    const sizes = [
      Size(320, 480),
      Size(400, 800),
      Size(430, 932),
      Size(800, 600),
      Size(1400, 800),
      Size(1920, 1080),
      Size(1200, 300),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            key: ValueKey(size),
            folderName: 'Math Lessons',
            lessons: const [
              Lesson(
                frontText:
                    'A long question that should wrap neatly inside the card '
                    'without spilling over the edges.',
                backText: 'A long answer that also needs to fit on the card.',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(const Key('flashcard_card')));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(size.width));
      expect(card.top, greaterThanOrEqualTo(0));
      expect(card.bottom, lessThanOrEqualTo(size.height));

      await tester.tap(find.byKey(const Key('flashcard_card')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final cardBack = tester.getRect(find.byKey(const Key('flashcard_card')));
      expect(cardBack.bottom, lessThanOrEqualTo(size.height));

      final good = tester.getRect(find.byKey(const Key('good_button')));
      final review = tester.getRect(
        find.byKey(const Key('review_again_button')),
      );
      expect(good.top, greaterThanOrEqualTo(cardBack.bottom));
      expect(review.top, greaterThanOrEqualTo(cardBack.bottom));
      expect(good.right, lessThan(review.left));
      expect(good.left, greaterThanOrEqualTo(0));
      expect(review.right, lessThanOrEqualTo(size.width));
      expect(review.bottom, lessThanOrEqualTo(size.height));
    }

    tester.view.reset();
  });

  testWidgets('a folder fits on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');

    expect(tester.takeException(), isNull);
    final folder = tester.getRect(
      find.image(const AssetImage('assets/images/folder_chiikawa.png')),
    );
    expect(folder.left, greaterThanOrEqualTo(0));
    expect(folder.right, lessThanOrEqualTo(320));
    expect(folder.top, greaterThanOrEqualTo(0));
  });

  testWidgets('Add Lessons asks for a folder first', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openAddLesson(tester);

    expect(find.text('Create a folder first!'), findsOneWidget);
    expect(find.byKey(const Key('add_lesson_screen')), findsNothing);
  });

  testWidgets('Add Lessons opens the clipboard form', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await openAddLesson(tester);

    expect(find.byKey(const Key('add_lesson_screen')), findsOneWidget);
    expect(find.text('ADD'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/clipboard2_notebook.png')),
      findsOneWidget,
    );
    expect(find.text('Folder:'), findsOneWidget);
    expect(find.text('Front:'), findsOneWidget);
    expect(find.text('Back:'), findsOneWidget);
    expect(find.byKey(const Key('lesson_front_field')), findsOneWidget);
    expect(find.byKey(const Key('lesson_back_field')), findsOneWidget);
    expect(find.text('Add front image'), findsOneWidget);
    expect(find.text('Add back image'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving a lesson returns home and confirms the folder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await openAddLesson(tester);

    await tester.enterText(
      find.byKey(const Key('lesson_front_field')),
      'What is 2 + 2?',
    );
    await tester.enterText(find.byKey(const Key('lesson_back_field')), '4');
    await tester.tap(find.byKey(const Key('lesson_save_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_lesson_screen')), findsNothing);
    expect(find.text('Lesson added to Math Lessons!'), findsOneWidget);
  });

  testWidgets('saving without text keeps the form open', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await openAddLesson(tester);

    await tester.tap(find.byKey(const Key('lesson_save_button')));
    await tester.pump();

    expect(find.byKey(const Key('add_lesson_screen')), findsOneWidget);
    expect(
      find.text('Write something on the front and the back!'),
      findsOneWidget,
    );
  });

  testWidgets('the lesson can be saved into a chosen folder', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await createFolder(tester, 'Studies Folder');
    await openAddLesson(tester);

    await tester.tap(find.byKey(const Key('lesson_folder_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Studies Folder').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('lesson_front_field')),
      'What is a noun?',
    );
    await tester.enterText(
      find.byKey(const Key('lesson_back_field')),
      'A naming word.',
    );
    await tester.tap(find.byKey(const Key('lesson_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Lesson added to Studies Folder!'), findsOneWidget);
  });

  testWidgets('the lesson form fits on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await openAddLesson(tester);

    expect(tester.takeException(), isNull);
    final save = tester.getRect(find.byKey(const Key('lesson_save_button')));
    expect(save.top, greaterThanOrEqualTo(0));
    expect(save.bottom, lessThanOrEqualTo(480));
    expect(find.byKey(const Key('lesson_front_field')), findsOneWidget);
  });

  testWidgets('the add options fit on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('add_button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final create = tester.getRect(
      find.byKey(const Key('create_folder_option')),
    );
    final lessons = tester.getRect(find.byKey(const Key('add_lessons_option')));
    expect(create.top, greaterThanOrEqualTo(0));
    expect(lessons.bottom, lessThanOrEqualTo(480));
  });

  testWidgets('tapping the menu button shows feedback', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('menu_button')));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('the search button opens the search screen', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_screen')), findsOneWidget);
    expect(find.byKey(const Key('search_field')), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search matches folders and both sides of lessons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'What is 2 + 2?', back: '4');
    await createFolder(tester, 'Studies Folder');

    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();

    // A folder name matches.
    await tester.enterText(find.byKey(const Key('search_field')), 'math');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_folder_0')), findsOneWidget);
    expect(find.byKey(const Key('search_folder_1')), findsNothing);
    expect(find.text('Math Lessons'), findsOneWidget);

    // Folder results carry no thumbnail.
    expect(
      find.descendant(
        of: find.byKey(const Key('search_folder_0')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );

    // The front of a lesson matches.
    await tester.enterText(find.byKey(const Key('search_field')), '2 + 2');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_lesson_0_0')), findsOneWidget);
    expect(find.text('What is 2 + 2?'), findsOneWidget);
    expect(find.text('in Math Lessons'), findsOneWidget);

    // The back of a lesson matches too.
    await tester.enterText(find.byKey(const Key('search_field')), '4');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_lesson_0_0')), findsOneWidget);

    // Unknown text finds nothing.
    await tester.enterText(find.byKey(const Key('search_field')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_no_results')), findsOneWidget);
    expect(find.text('What is 2 + 2?'), findsNothing);

    // Clearing brings the prompt back.
    await tester.tap(find.byKey(const Key('search_clear_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search_empty_prompt')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a folder result opens the folder options', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');

    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search_field')), 'math');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('search_folder_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_screen')), findsNothing);
    expect(find.byKey(const Key('flashcards_option')), findsOneWidget);
    expect(find.byKey(const Key('quiz_option')), findsOneWidget);
  });

  testWidgets('a folder can be deleted from its options', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');

    await openFolderOptions(tester, 'Math Lessons');
    await tester.tap(find.byKey(const Key('delete_folder_option')));
    await tester.pumpAndSettle();

    expect(find.text('Delete Folder'), findsOneWidget);
    expect(find.text('Delete "Math Lessons" and its lessons?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_delete_folder')));
    await tester.pumpAndSettle();

    expect(find.text('Math Lessons'), findsNothing);
    expect(find.byKey(const Key('folder_list')), findsNothing);
    expect(find.text("There's nothing here..."), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the delete keeps the folder', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');

    await openFolderOptions(tester, 'Math Lessons');
    await tester.tap(find.byKey(const Key('delete_folder_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel_delete_folder')));
    await tester.pumpAndSettle();

    expect(find.text('Math Lessons'), findsOneWidget);
    expect(find.byKey(const Key('folder_list')), findsOneWidget);
  });

  testWidgets('lessons can be deleted from the manage screen', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await createFolder(tester, 'Math Lessons');
    await addLesson(tester, front: 'Front one', back: 'Back one');
    await addLesson(tester, front: 'Front two', back: 'Back two');

    await openFolderOptions(tester, 'Math Lessons');
    await tester.tap(find.byKey(const Key('manage_lessons_option')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_lessons_screen')), findsOneWidget);
    expect(find.text('Front one'), findsOneWidget);
    expect(find.text('Front two'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_lesson_0')));
    await tester.pumpAndSettle();
    expect(find.text('Delete Lesson'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_delete_lesson')));
    await tester.pumpAndSettle();

    expect(find.text('Front one'), findsNothing);
    expect(find.text('Front two'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_lesson_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_lesson')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_lessons_empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search screen fits every screen size', (tester) async {
    await _loadFonts();

    final folders = [
      StudyFolder('Math Lessons')
        ..lessons.add(const Lesson(frontText: 'What is 2 + 2?', backText: '4')),
      StudyFolder('Studies Folder')
        ..lessons.add(
          const Lesson(
            frontText: 'What is a noun?',
            backText: 'A naming word.',
          ),
        ),
    ];

    const sizes = [
      Size(320, 480),
      Size(400, 800),
      Size(430, 932),
      Size(800, 600),
      Size(1400, 800),
      Size(1920, 1080),
      Size(1200, 300),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(key: ValueKey(size), folders: folders),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final field = tester.getRect(find.byKey(const Key('search_field')));
      expect(field.left, greaterThanOrEqualTo(0));
      expect(field.right, lessThanOrEqualTo(size.width));
      expect(field.top, greaterThanOrEqualTo(0));
      expect(field.bottom, lessThanOrEqualTo(size.height));

      await tester.enterText(find.byKey(const Key('search_field')), 'a');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final result = tester.getRect(find.byKey(const Key('search_folder_0')));
      expect(result.left, greaterThanOrEqualTo(0));
      expect(result.right, lessThanOrEqualTo(size.width));
      expect(result.top, greaterThanOrEqualTo(field.bottom));
      expect(result.bottom, lessThanOrEqualTo(size.height));
    }

    tester.view.reset();
  });
}
