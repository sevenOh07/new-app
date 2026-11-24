import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/study_folder.dart';

/// The pink shared by the app's panels and the search field.
const Color _panelPink = Color(0xFFE6BEBE);

/// Ink colours written over the white paper.
const Color _ink = Color(0xFF2B2320);
const Color _fadedInk = Color(0xFF8A6D62);

/// A full-screen search over folder names and the text on both sides of every
/// lesson. Pops with the folder that was picked so the home screen can open it.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.folders});

  /// The folders to search, in home-screen order.
  final List<StudyFolder> folders;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// A lesson that matched the query, plus where it lives.
class _LessonHit {
  const _LessonHit({
    required this.folder,
    required this.folderIndex,
    required this.lesson,
    required this.lessonIndex,
  });

  final StudyFolder folder;
  final int folderIndex;
  final Lesson lesson;
  final int lessonIndex;
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Whether [text] contains the current query, ignoring case.
  bool _matches(String text, String needle) {
    return text.toLowerCase().contains(needle);
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  void _openFolder(StudyFolder folder) {
    Navigator.of(context).pop(folder);
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();

    final folderHits = <int>[];
    final lessonHits = <_LessonHit>[];

    if (needle.isNotEmpty) {
      for (final entry in widget.folders.asMap().entries) {
        final folderIndex = entry.key;
        final folder = entry.value;

        if (_matches(folder.name, needle)) {
          folderHits.add(folderIndex);
        }

        for (final lessonEntry in folder.lessons.asMap().entries) {
          final lesson = lessonEntry.value;
          if (_matches(lesson.frontText, needle) ||
              _matches(lesson.backText, needle)) {
            lessonHits.add(
              _LessonHit(
                folder: folder,
                folderIndex: folderIndex,
                lesson: lesson,
                lessonIndex: lessonEntry.key,
              ),
            );
          }
        }
      }
    }

    final Widget content;
    if (needle.isEmpty) {
      content = _buildPrompt();
    } else if (folderHits.isEmpty && lessonHits.isEmpty) {
      content = _buildNoResults();
    } else {
      content = _buildResults(folderHits, lessonHits);
    }

    return Scaffold(
      key: const Key('search_screen'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchField(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  /// The back arrow and the screen title.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('search_back_button'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back to folders',
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          const SizedBox(width: 4),
          const Text(
            'SEARCH',
            style: TextStyle(
              fontFamily: 'Doodle_Head',
              fontSize: 40,
              color: Colors.black,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// The doodle-pink search field, with a clear button once something is typed.
  Widget _buildSearchField() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            key: const Key('search_field'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(
              fontFamily: 'Doodle_Head',
              fontSize: 24,
              color: _ink,
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: 'Search folders and lessons...',
              hintStyle: const TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 22,
                color: Color(0xFFB4A39C),
                height: 1.2,
              ),
              prefixIcon: const Icon(Icons.search, color: _fadedInk, size: 26),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('search_clear_button'),
                      onPressed: _clear,
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, color: _fadedInk, size: 22),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: _panelPink, width: 3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: _panelPink, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shown before anything is typed.
  Widget _buildPrompt() {
    final nothingToSearch = widget.folders.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = math.min(200.0, constraints.maxHeight * 0.4);

        return SingleChildScrollView(
          key: const Key('search_empty_prompt'),
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 32),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageSize > 60)
                  Image.asset(
                    'assets/images/chiikawa_confused.png',
                    width: imageSize,
                    height: imageSize,
                  ),
                if (imageSize > 60) const SizedBox(height: 16),
                Text(
                  nothingToSearch
                      ? 'Nothing to search yet...'
                      : 'What are you looking for?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 30,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nothingToSearch
                      ? 'Create a folder and add lessons first!'
                      : 'Search folder names, lesson fronts, and backs.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 18,
                    color: _fadedInk,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shown when a query matches nothing.
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nothing found...',
              key: Key('search_no_results'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 30,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different word.',
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

  /// Folder matches first, then lesson matches.
  Widget _buildResults(List<int> folderHits, List<_LessonHit> lessonHits) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          key: const Key('search_results'),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (folderHits.isNotEmpty) ...[
              const _SectionLabel('Folders'),
              for (final folderIndex in folderHits) ...[
                _ResultTile(
                  key: ValueKey('search_folder_$folderIndex'),
                  title: widget.folders[folderIndex].name,
                  subtitle: _lessonCountLabel(
                    widget.folders[folderIndex].lessons.length,
                  ),
                  onTap: () => _openFolder(widget.folders[folderIndex]),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (lessonHits.isNotEmpty) ...[
              const _SectionLabel('Lessons'),
              for (final hit in lessonHits) ...[
                _ResultTile(
                  key: ValueKey(
                    'search_lesson_${hit.folderIndex}_${hit.lessonIndex}',
                  ),
                  leading: const Icon(
                    Icons.style_outlined,
                    color: _fadedInk,
                    size: 30,
                  ),
                  title: hit.lesson.frontText,
                  subtitle: 'in ${hit.folder.name}',
                  onTap: () => _openFolder(hit.folder),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _lessonCountLabel(int count) {
    return count == 1 ? '1 lesson' : '$count lessons';
  }
}

/// A small doodle heading above a group of results.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Doodle_Head',
          fontSize: 24,
          color: _fadedInk,
          height: 1,
        ),
      ),
    );
  }
}

/// One tappable search result: an optional icon or thumbnail, a title, and a
/// subtitle.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    super.key,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget? leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDF2F2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _panelPink.withValues(alpha: 0.7),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: 56, child: Center(child: leading)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
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
                      subtitle,
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
              const Icon(Icons.chevron_right, color: _fadedInk),
            ],
          ),
        ),
      ),
    );
  }
}
