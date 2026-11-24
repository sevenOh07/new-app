import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../widgets/confirm_dialog.dart';

/// The ink colours written over the white paper.
const Color _ink = Color(0xFF2B2320);
const Color _fadedInk = Color(0xFF8A6D62);
const Color _panelPink = Color(0xFFE6BEBE);
const Color _deleteRed = Color(0xFFC0504D);

/// Lists every lesson in a folder so the member can delete them one at a time.
///
/// The lessons are the folder's own list, so deleting here is reflected as soon
/// as the screen closes.
class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({
    super.key,
    required this.folderName,
    required this.lessons,
  });

  final String folderName;
  final List<Lesson> lessons;

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  Future<void> _confirmDelete(Lesson lesson) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (dialogContext) => ConfirmDialog(
        title: 'Delete Lesson',
        message: 'Delete "${lesson.frontText}"?',
        cancelKey: const Key('cancel_delete_lesson'),
        confirmKey: const Key('confirm_delete_lesson'),
      ),
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    setState(() => widget.lessons.remove(lesson));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('manage_lessons_screen'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: widget.lessons.isEmpty
                  ? _buildEmpty()
                  : _buildLessonList(),
            ),
          ],
        ),
      ),
    );
  }

  /// The back arrow and the folder whose lessons are listed.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('manage_lessons_back_button'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back to folders',
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 46),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.folderName,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 36,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A hint, plus the lessons and their delete buttons.
  Widget _buildLessonList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.separated(
          key: const Key('manage_lessons_list'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: widget.lessons.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(6, 4, 6, 0),
                child: Text(
                  'Tap the bin to delete a lesson.',
                  style: TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 18,
                    color: _fadedInk,
                    height: 1.2,
                  ),
                ),
              );
            }

            final lessonIndex = index - 1;
            final lesson = widget.lessons[lessonIndex];

            return _LessonRow(
              key: ValueKey('manage_lesson_$lessonIndex'),
              lesson: lesson,
              onDelete: () => _confirmDelete(lesson),
              deleteKey: ValueKey('delete_lesson_$lessonIndex'),
            );
          },
        ),
      ),
    );
  }

  /// Shown once every lesson has been deleted.
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          key: const Key('manage_lessons_empty'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No lessons left...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 32,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new lesson from the home screen!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 18,
                color: _fadedInk.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One lesson: its two sides, and a bin button on the right.
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    super.key,
    required this.lesson,
    required this.onDelete,
    required this.deleteKey,
  });

  final Lesson lesson;
  final VoidCallback onDelete;
  final Key deleteKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _panelPink.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lesson.frontText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 22,
                    color: _ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.backText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 16,
                    color: _fadedInk,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: deleteKey,
            onPressed: onDelete,
            tooltip: 'Delete lesson',
            iconSize: 26,
            color: _deleteRed,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
