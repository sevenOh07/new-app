import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'flashcard.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/study_folder.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_drawer.dart';
import 'add_lesson_screen.dart';
import 'manage_lessons_screen.dart';
import 'quiz.dart';
import 'search_screen.dart';

/// The pink shared by the add-options panel and the create-folder dialog.
const Color _panelPink = Color(0xFFE6BEBE);

/// The home screen: an empty state that Chiikawa stands in until folders are
/// added, then a scrollable list of folders.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// grassy_background.png is 864 x 1537.
  static const double _grassAspect = 864 / 1537;

  /// The top 162 pixels of the grass PNG are fully transparent, so the visible
  /// green edge starts this far into the image.
  static const double _grassGreenStart = 162 / 1537;

  /// Chiikawa's feet sit 602 pixels down her 736 pixel tall PNG (the rest is
  /// transparent padding), which is the line she should stand on.
  static const double _chiikawaFeet = 602 / 736;

  /// Chiikawa's width as a fraction of the screen width.
  static const double _chiikawaWidthFactor = 0.90;

  /// Where the top edge of the grass sits, as a fraction of the screen height.
  /// Her feet are placed exactly on this line.
  static const double _grassLineFactor = 0.58;

  /// ---------------------------------------------------------------------
  /// Empty-state message. Tweak these to adjust the text without touching the
  /// layout code below.
  /// ---------------------------------------------------------------------

  /// The message shown when there are no folders yet.
  static const String _message = "There's nothing here...";

  /// Message font size in logical pixels.
  static const double _messageFontSize = 45;

  /// Distance from the top of the screen to the top of the message, as a
  /// fraction of the screen height. Increase it to move the text down.
  static const double _messageTopFactor = 0.15;

  /// Horizontal breathing room on each side of the message.
  static const double _messageSidePadding = 24;

  /// Minimum white space kept between the message and Chiikawa's head.
  static const double _messageGap = 10;

  /// Folders created in this session, in the order they were added.
  final List<StudyFolder> _folders = <StudyFolder>[];

  /// Opens and closes the Status side menu.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Study history for each card, shown in the Status side menu.
  final Map<Lesson, LessonProgress> _progress = <Lesson, LessonProgress>{};

  /// Total time spent in flashcard and quiz sessions.
  Duration _studyTime = Duration.zero;

  /// The part of [_studyTime] earned today.
  Duration _todayStudyTime = Duration.zero;

  /// The day [_todayStudyTime] belongs to.
  DateTime _studyDay = DateUtils.dateOnly(DateTime.now());

  LessonProgress _progressFor(Lesson lesson) {
    return _progress.putIfAbsent(lesson, () => LessonProgress());
  }

  void _recordReview(Lesson lesson, bool correct) {
    _progressFor(lesson).record(correct: correct);
  }

  void _addStudyTime(Duration elapsed) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (!DateUtils.isSameDay(today, _studyDay)) {
      _studyDay = today;
      _todayStudyTime = Duration.zero;
    }
    _studyTime += elapsed;
    _todayStudyTime += elapsed;
  }

  /// Opens the pink panel with the two add options: Create Folder and
  /// Add Lessons (page 3 of the mockup).
  Future<void> _showAddOptions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: _AddOptionsCard(
            onCreateFolder: () {
              Navigator.of(sheetContext).pop();
              _promptCreateFolder(context);
            },
            onAddLessons: () {
              Navigator.of(sheetContext).pop();
              _openAddLesson();
            },
          ),
        );
      },
    );
  }

  /// Asks for a folder name and adds the folder once the name is confirmed.
  Future<void> _promptCreateFolder(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (dialogContext) => const _CreateFolderDialog(),
    );

    if (!mounted) {
      return;
    }

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      return;
    }

    setState(() => _folders.add(StudyFolder(trimmed)));
  }

  /// Opens the clipboard form so the member can add a lesson to a folder.
  Future<void> _openAddLesson() async {
    if (_folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a folder first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final draft = await Navigator.of(context).push<LessonDraft>(
      MaterialPageRoute<LessonDraft>(
        builder: (context) => AddLessonScreen(
          folderNames: [for (final folder in _folders) folder.name],
        ),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    final folder = _folders[draft.folderIndex];
    setState(() => folder.lessons.add(draft.lesson));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesson added to ${folder.name}!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Asks how the member wants to study a folder, then opens that mode.
  Future<void> _openFolder(StudyFolder folder) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: _FolderOptionsCard(
            folderName: folder.name,
            hasLessons: folder.lessons.isNotEmpty,
            onFlashcards: () {
              Navigator.of(sheetContext).pop();
              _openFlashcards(folder);
            },
            onQuiz: () {
              Navigator.of(sheetContext).pop();
              _openQuiz(folder);
            },
            onManageLessons: () {
              Navigator.of(sheetContext).pop();
              _openManageLessons(folder);
            },
            onDeleteFolder: () {
              Navigator.of(sheetContext).pop();
              _confirmDeleteFolder(folder);
            },
          ),
        );
      },
    );
  }

  /// Opens the search screen, then shows the study options for whichever
  /// folder the member picked from the results.
  Future<void> _openSearch() async {
    final folder = await Navigator.of(context).push<StudyFolder>(
      MaterialPageRoute<StudyFolder>(
        builder: (context) => SearchScreen(folders: _folders),
      ),
    );

    if (!mounted || folder == null) {
      return;
    }

    await _openFolder(folder);
  }

  /// Opens the list of a folder's lessons, where they can be deleted.
  Future<void> _openManageLessons(StudyFolder folder) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ManageLessonsScreen(
          folderName: folder.name,
          lessons: folder.lessons,
        ),
      ),
    );
  }

  /// Asks before removing a folder and all of its lessons.
  Future<void> _confirmDeleteFolder(StudyFolder folder) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (dialogContext) => ConfirmDialog(
        title: 'Delete Folder',
        message: 'Delete "${folder.name}" and its lessons?',
        cancelKey: const Key('cancel_delete_folder'),
        confirmKey: const Key('confirm_delete_folder'),
      ),
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    setState(() {
      _folders.remove(folder);
      for (final lesson in folder.lessons) {
        _progress.remove(lesson);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Folder deleted!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Opens the flip cards for a folder. Pass [lessons] to study a single card.
  Future<void> _openFlashcards(
    StudyFolder folder, {
    List<Lesson>? lessons,
  }) async {
    final started = DateTime.now();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => FlashcardScreen(
          folderName: folder.name,
          lessons: lessons ?? folder.lessons,
          onReviewed: _recordReview,
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() => _addStudyTime(DateTime.now().difference(started)));
  }

  /// Opens the multiple-choice quiz for a folder. A quiz needs at least two
  /// cards so there is something to choose between.
  Future<void> _openQuiz(StudyFolder folder) async {
    if (folder.lessons.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 lessons to start a quiz!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final started = DateTime.now();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => QuizScreen(
          folderName: folder.name,
          lessons: folder.lessons,
          onAnswered: _recordReview,
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    setState(() => _addStudyTime(DateTime.now().difference(started)));
  }

  /// Closes the Status menu and studies one card from it.
  void _viewCard(StudyFolder folder, Lesson lesson) {
    _openFlashcards(folder, lessons: <Lesson>[lesson]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: StatusDrawer(
        folders: _folders,
        progress: _progress,
        totalStudyTime: _studyTime,
        todayStudyTime: _todayStudyTime,
        onViewCard: _viewCard,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // The line Chiikawa stands on, and where the green starts.
          final grassLine = height * _grassLineFactor;

          // Where the message sits. It is pinned to the screen, so resizing
          // the window never slides it around.
          final messageTop = height * _messageTopFactor;
          final messageHeight = _messageFontSize * 1.35;

          // Shrink Chiikawa only if the space left below the message and
          // above the grass line is too short for her.
          final reservedAbove = messageTop + messageHeight + _messageGap;
          final maxChiikawaSize = math.max(
            0.0,
            (grassLine - reservedAbove) / _chiikawaFeet,
          );
          final chiikawaSize = math.min(
            width * _chiikawaWidthFactor,
            maxChiikawaSize,
          );

          // Grass keeps a fixed scale (from the screen width) and is tall
          // enough to always reach the bottom of the screen.
          final grassHeight = math.max(
            width / _grassAspect,
            (height - grassLine) / (1 - _grassGreenStart),
          );
          final grassWidth = grassHeight * _grassAspect;
          final grassTop = grassLine - grassHeight * _grassGreenStart;

          // Her image box is pushed below the line by its own bottom padding.
          final chiikawaBottom = grassLine + chiikawaSize * (1 - _chiikawaFeet);

          // Corner buttons, sized from the screen but kept in a comfortable
          // range.
          final buttonHeight = math.max(48.0, math.min(80.0, width * 0.15));
          final buttonMargin = math.max(12.0, math.min(32.0, width * 0.05));

          // Folders start below the top buttons and can scroll behind the
          // plus button, which keeps the last row reachable.
          final folderTop = buttonMargin + buttonHeight + 16;
          final folderBottom = buttonMargin + buttonHeight + 12;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              //this da grass
              Positioned(
                left: (width - grassWidth) / 2,
                top: grassTop,
                width: grassWidth,
                height: grassHeight,
                child: Image.asset(
                  'assets/images/grassy_background.png',
                  fit: BoxFit.fill,
                ),
              ),

              // Empty state: the message and Chiikawa give way to the folders.
              if (_folders.isEmpty) ...[
                //empty-state message, pinned just below the top buttons
                Positioned(
                  left: _messageSidePadding,
                  right: _messageSidePadding,
                  top: messageTop,
                  height: messageHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _message,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontFamily: 'Doodle_Head',
                        fontSize: _messageFontSize,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                //foreground chiikawa, standing on the green edge
                Positioned(
                  left: (width - chiikawaSize) / 2,
                  bottom: height - chiikawaBottom,
                  child: Image.asset(
                    'assets/images/chiikawa_confused.png',
                    width: chiikawaSize,
                    height: chiikawaSize,
                  ),
                ),
              ] else
                Positioned(
                  left: 0,
                  right: 0,
                  top: folderTop,
                  bottom: 0,
                  child: ListView.separated(
                    key: const Key('folder_list'),
                    padding: EdgeInsets.fromLTRB(20, 0, 20, folderBottom),
                    itemCount: _folders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return _FolderTile(
                        key: ValueKey('folder_$index'),
                        name: folder.name,
                        onTap: () => _openFolder(folder),
                      );
                    },
                  ),
                ),

              //menu button, top left corner
              Positioned(
                left: buttonMargin,
                top: buttonMargin,
                child: _CornerButton(
                  key: const Key('menu_button'),
                  asset: 'assets/images/menu.png',
                  height: buttonHeight,
                  tooltip: 'Status',
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),

              //search button, top right corner
              Positioned(
                right: buttonMargin,
                top: buttonMargin,
                child: _CornerButton(
                  key: const Key('search_button'),
                  asset: 'assets/images/search.png',
                  height: buttonHeight,
                  tooltip: 'Search',
                  onTap: _openSearch,
                ),
              ),

              //plus button, bottom right corner
              Positioned(
                right: buttonMargin,
                bottom: buttonMargin,
                child: _CornerButton(
                  key: const Key('add_button'),
                  asset: 'assets/images/plus_sign.png',
                  height: buttonHeight,
                  tooltip: 'Add note',
                  onTap: () => _showAddOptions(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A doodle-style image button used in the corners of the screen.
class _CornerButton extends StatelessWidget {
  const _CornerButton({
    super.key,
    required this.asset,
    required this.height,
    required this.tooltip,
    required this.onTap,
  });

  final String asset;
  final double height;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Ink.image(
              image: AssetImage(asset),
              width: height * 145 / 137,
              height: height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

/// One folder in the list: the doodle folder art with its name on top.
class _FolderTile extends StatelessWidget {
  const _FolderTile({super.key, required this.name, required this.onTap});

  /// folder_chiikawa.png is 1947 x 871.
  static const double _aspectRatio = 1947 / 871;

  /// Keep folders from growing too wide on desktop windows.
  static const double _maxWidth = 560;

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: Semantics(
            button: true,
            label: 'Folder $name',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                onTap: onTap,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fontSize = math.min(
                      math.max(constraints.maxWidth * 0.085, 20.0),
                      38.0,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/folder_chiikawa.png',
                          fit: BoxFit.fill,
                        ),
                        Align(
                          alignment: const Alignment(0, -0.1),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth * 0.14,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                name,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'Doodle_Head',
                                  fontSize: fontSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pink panel with the study modes and folder actions, shown when a folder
/// is tapped.
class _FolderOptionsCard extends StatelessWidget {
  const _FolderOptionsCard({
    required this.folderName,
    required this.hasLessons,
    required this.onFlashcards,
    required this.onQuiz,
    required this.onManageLessons,
    required this.onDeleteFolder,
  });

  final String folderName;
  final bool hasLessons;
  final VoidCallback onFlashcards;
  final VoidCallback onQuiz;
  final VoidCallback onManageLessons;
  final VoidCallback onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = math.max(16.0, math.min(28.0, width * 0.05));
    final buttonHeight = math.max(56.0, math.min(76.0, width * 0.17));
    final fontSize = math.max(26.0, math.min(40.0, width * 0.1));

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _panelPink,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding * 0.5),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                folderName,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: math.max(26.0, math.min(34.0, width * 0.075)),
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: padding),
          if (hasLessons) ...[
            _OptionButton(
              key: const Key('flashcards_option'),
              label: 'Flash Cards',
              height: buttonHeight,
              fontSize: fontSize,
              onTap: onFlashcards,
            ),
            SizedBox(height: padding),
            _OptionButton(
              key: const Key('quiz_option'),
              label: 'Quiz',
              height: buttonHeight,
              fontSize: fontSize,
              onTap: onQuiz,
            ),
          ] else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding * 0.5),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'This folder has no lessons yet!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: math.max(18.0, math.min(24.0, width * 0.055)),
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          SizedBox(height: padding),
          _OptionButton(
            key: const Key('manage_lessons_option'),
            label: 'Manage Lessons',
            height: buttonHeight,
            fontSize: fontSize,
            onTap: onManageLessons,
          ),
          SizedBox(height: padding),
          _OptionButton(
            key: const Key('delete_folder_option'),
            label: 'Delete Folder',
            height: buttonHeight,
            fontSize: fontSize,
            fillColor: const Color(0xFFC0504D),
            onTap: onDeleteFolder,
          ),
        ],
      ),
    );
  }
}

/// The pink panel with the two add options, shown when the plus is tapped.
class _AddOptionsCard extends StatelessWidget {
  const _AddOptionsCard({
    required this.onCreateFolder,
    required this.onAddLessons,
  });

  final VoidCallback onCreateFolder;
  final VoidCallback onAddLessons;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = math.max(16.0, math.min(28.0, width * 0.05));
    final buttonHeight = math.max(56.0, math.min(76.0, width * 0.17));
    final fontSize = math.max(26.0, math.min(40.0, width * 0.1));

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _panelPink,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OptionButton(
            key: const Key('create_folder_option'),
            label: 'Create Folder',
            height: buttonHeight,
            fontSize: fontSize,
            onTap: onCreateFolder,
          ),
          SizedBox(height: padding),
          _OptionButton(
            key: const Key('add_lessons_option'),
            label: 'Add Lessons',
            height: buttonHeight,
            fontSize: fontSize,
            onTap: onAddLessons,
          ),
        ],
      ),
    );
  }
}

/// A white-outlined pill button inside [_AddOptionsCard].
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.label,
    required this.height,
    required this.fontSize,
    required this.onTap,
    this.fillColor,
  });

  final String label;
  final double height;
  final double fontSize;
  final VoidCallback onTap;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: fillColor ?? Colors.white.withValues(alpha: 0.08),
          side: const BorderSide(color: Colors.white, width: 3),
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
          textStyle: TextStyle(
            fontFamily: 'Doodle_Head',
            fontSize: fontSize,
            height: 1,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Asks for the new folder's name before it is created.
class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog();

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'New Folder');
    // Pre-select the default name so typing replaces it.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _panelPink,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Folder',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const Key('folder_name_field'),
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 24,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Folder name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                final canCreate = value.text.trim().isNotEmpty;
                return Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        key: const Key('cancel_folder_button'),
                        label: 'Cancel',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        key: const Key('confirm_folder_button'),
                        label: 'Create',
                        onTap: canCreate ? _submit : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A white-outlined pill button inside the create-folder dialog.
class _DialogButton extends StatelessWidget {
  const _DialogButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          side: BorderSide(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white,
            width: 3,
          ),
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontFamily: 'Doodle_Head',
            fontSize: 24,
            height: 1,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
