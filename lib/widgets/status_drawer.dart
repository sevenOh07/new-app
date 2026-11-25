import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/study_folder.dart';

const Color _ink = Color(0xFF2B2320);
const Color _softInk = Color(0xFF6B5B52);
const Color _line = Color(0xFFE2DED8);
const Color _blue = Color(0xFF2F9BD8);
const Color _green = Color(0xFF6BBF4A);
const Color _red = Color(0xFFD9534F);

/// The left-hand menu opened by the menu button: a "Status" panel with the
/// deck's score, study time, card breakdown, and a filterable card list.
class StatusDrawer extends StatefulWidget {
  const StatusDrawer({
    super.key,
    required this.folders,
    required this.progress,
    required this.totalStudyTime,
    required this.todayStudyTime,
    required this.onViewCard,
  });

  final List<StudyFolder> folders;
  final Map<Lesson, LessonProgress> progress;
  final Duration totalStudyTime;
  final Duration todayStudyTime;
  final void Function(StudyFolder folder, Lesson lesson) onViewCard;

  @override
  State<StatusDrawer> createState() => _StatusDrawerState();
}

class _StatusDrawerState extends State<StatusDrawer> {
  _Range _range = _Range.all;
  CardStatus? _filter;

  List<_CardEntry> get _cards => [
    for (final folder in widget.folders)
      for (final lesson in folder.lessons)
        _CardEntry(folder, lesson, widget.progress[lesson]),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cards = _cards;
    final reviewed = _reviewedInRange(cards);
    final score = reviewed.total == 0
        ? null
        : reviewed.correct / reviewed.total;

    final todayStart = DateUtils.dateOnly(DateTime.now());
    final todayReviewed = cards
        .where(
          (card) =>
              card.lastReviewedAt != null &&
              !card.lastReviewedAt!.isBefore(todayStart),
        )
        .toList();
    final todayCorrect = todayReviewed
        .where((card) => card.lastReviewCorrect)
        .length;
    final todayScore = todayReviewed.isEmpty
        ? null
        : todayCorrect / todayReviewed.length;

    final visibleCards = _filter == null
        ? cards
        : cards.where((card) => card.status == _filter).toList();

    return Drawer(
      key: const Key('status_drawer'),
      width: math.min(screenWidth * 0.88, 430.0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                children: [
                  _buildRangeTabs(),
                  const SizedBox(height: 14),
                  _buildStatsCard(score, todayScore),
                  const SizedBox(height: 14),
                  _buildBreakdown(cards),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 8),
                  if (cards.isEmpty)
                    _buildEmpty(
                      'No cards yet!\nAdd a lesson to see its status.',
                    )
                  else if (visibleCards.isEmpty)
                    _buildEmpty('No ${_filterLabel(_filter)} cards yet!')
                  else
                    for (final card in visibleCards) _buildCardRow(card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          _CircleButton(
            key: const Key('status_close_button'),
            icon: Icons.arrow_back_ios_new,
            onTap: () => Scaffold.of(context).closeDrawer(),
          ),
          Expanded(
            child: Text(
              'Status',
              key: const Key('status_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 32,
                color: _ink,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildRangeTabs() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEC),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final range in _Range.values)
            Expanded(
              child: _RangeTab(
                key: Key('status_tab_${range.name}'),
                label: range.label,
                selected: range == _range,
                onTap: () => setState(() => _range = range),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(double? score, double? todayScore) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _buildStatRow(
            label: 'Deck Score:',
            value: score == null ? '-' : '${(score * 100).round()}%',
            valueKey: const Key('status_score'),
            detail: todayScore == null
                ? null
                : '(${(todayScore * 100).round()}% today)',
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 8),
          _buildStatRow(
            label: 'Total Study Time:',
            value: _formatDuration(widget.totalStudyTime),
            valueKey: const Key('status_study_time'),
            detail: '(+${_formatDuration(widget.todayStudyTime)} today)',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Key valueKey,
    String? detail,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: 18,
                  color: _ink,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              key: valueKey,
              style: const TextStyle(
                fontFamily: 'Mix Doodle',
                fontSize: 26,
                color: _ink,
                height: 1,
              ),
            ),
          ],
        ),
        if (detail != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                detail,
                style: const TextStyle(
                  fontFamily: 'Mix Doodle',
                  fontSize: 13,
                  color: _green,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBreakdown(List<_CardEntry> cards) {
    var newCount = 0;
    var reviewCount = 0;
    var learningCount = 0;
    for (final card in cards) {
      switch (card.status) {
        case CardStatus.newCard:
          newCount++;
        case CardStatus.review:
          reviewCount++;
        case CardStatus.learning:
          learningCount++;
      }
    }
    final total = cards.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final donutSize = math.min(116.0, constraints.maxWidth * 0.38);

          return Row(
            children: [
              SizedBox(
                width: donutSize,
                height: donutSize,
                child: CustomPaint(
                  painter: _DonutPainter(
                    newCount: newCount,
                    reviewCount: reviewCount,
                    learningCount: learningCount,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontFamily: 'Mix Doodle',
                            fontSize: 24,
                            color: _ink,
                            height: 1,
                          ),
                        ),
                        Text(
                          total == 1 ? 'Card' : 'Cards',
                          style: const TextStyle(
                            fontFamily: 'Doodle_Head',
                            fontSize: 12,
                            color: _softInk,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _buildLegend(_blue, 'New Cards', newCount, total),
                    _buildLegend(_green, 'Review Cards', reviewCount, total),
                    _buildLegend(_red, 'Learning Cards', learningCount, total),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(Color color, String label, int count, int total) {
    final percent = total == 0 ? 0 : (count * 100 / total).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$label ($count) - $percent%',
                style: const TextStyle(
                  fontFamily: 'Mix Doodle',
                  fontSize: 13,
                  color: _ink,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _FilterTab(
          key: const Key('status_filter_all'),
          label: 'All',
          color: _ink,
          selected: _filter == null,
          onTap: () => setState(() => _filter = null),
        ),
        _FilterTab(
          key: const Key('status_filter_new'),
          label: 'New',
          color: _blue,
          selected: _filter == CardStatus.newCard,
          onTap: () => setState(() => _filter = CardStatus.newCard),
        ),
        _FilterTab(
          key: const Key('status_filter_review'),
          label: 'Review',
          color: _green,
          selected: _filter == CardStatus.review,
          onTap: () => setState(() => _filter = CardStatus.review),
        ),
        _FilterTab(
          key: const Key('status_filter_learning'),
          label: 'Learning',
          color: _red,
          selected: _filter == CardStatus.learning,
          onTap: () => setState(() => _filter = CardStatus.learning),
        ),
      ],
    );
  }

  Widget _buildCardRow(_CardEntry card) {
    final color = _statusColor(card.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(
            'status_card_${card.folder.name}_${card.lesson.frontText}',
          ),
          onTap: () => _viewCard(card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFD6D1CB),
                      width: 1.8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.lesson.frontText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Doodle_Head',
                      fontSize: 15,
                      color: _ink,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'View Card',
                  style: TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: 11,
                    color: _softInk,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Padding(
      key: const Key('status_empty'),
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Doodle_Head',
          fontSize: 18,
          color: _softInk,
          height: 1.2,
        ),
      ),
    );
  }

  void _viewCard(_CardEntry card) {
    Scaffold.of(context).closeDrawer();
    widget.onViewCard(card.folder, card.lesson);
  }

  ({int correct, int total}) _reviewedInRange(List<_CardEntry> cards) {
    final window = _range.window;
    final cutoff = window == null ? null : DateTime.now().subtract(window);

    var correct = 0;
    var total = 0;
    for (final card in cards) {
      final at = card.lastReviewedAt;
      if (at == null) {
        continue;
      }
      if (cutoff != null && at.isBefore(cutoff)) {
        continue;
      }
      total++;
      if (card.lastReviewCorrect) {
        correct++;
      }
    }

    return (correct: correct, total: total);
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _line, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  String _filterLabel(CardStatus? status) {
    return switch (status) {
      CardStatus.newCard => 'new',
      CardStatus.review => 'review',
      CardStatus.learning => 'learning',
      null => '',
    };
  }
}

class _CardEntry {
  const _CardEntry(this.folder, this.lesson, this.progress);

  final StudyFolder folder;
  final Lesson lesson;
  final LessonProgress? progress;

  CardStatus get status => progress?.status ?? CardStatus.newCard;
  DateTime? get lastReviewedAt => progress?.lastReviewedAt;
  bool get lastReviewCorrect => progress?.lastReviewCorrect ?? false;
}

Color _statusColor(CardStatus status) {
  return switch (status) {
    CardStatus.newCard => _blue,
    CardStatus.review => _green,
    CardStatus.learning => _red,
  };
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes <= 0) {
    return '0 min';
  }
  if (minutes < 60) {
    return '$minutes min';
  }

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

enum _Range {
  day('1D', Duration(days: 1)),
  week('7D', Duration(days: 7)),
  month('1M', Duration(days: 30)),
  quarter('3M', Duration(days: 90)),
  all('All', null);

  const _Range(this.label, this.window);

  final String label;
  final Duration? window;
}

class _RangeTab extends StatelessWidget {
  const _RangeTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected ? _blue : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Mix Doodle',
                fontSize: 16,
                color: selected ? Colors.white : _softInk,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? color : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Doodle_Head',
                      fontSize: 14,
                      color: selected ? color : _softInk,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F2EF),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: _ink),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.newCount,
    required this.reviewCount,
    required this.learningCount,
  });

  final int newCount;
  final int reviewCount;
  final int learningCount;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFE9E5E1);
    canvas.drawArc(arcRect, 0, math.pi * 2, false, background);

    final total = newCount + reviewCount + learningCount;
    if (total == 0) {
      return;
    }

    var start = -math.pi / 2;
    const gap = 0.035;

    void drawSegment(int count, Color color) {
      if (count == 0) {
        return;
      }
      final sweep = math.pi * 2 * count / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color;
      if (sweep > gap * 2) {
        canvas.drawArc(arcRect, start + gap / 2, sweep - gap, false, paint);
      } else {
        canvas.drawArc(arcRect, start, sweep, false, paint);
      }
      start += sweep;
    }

    drawSegment(newCount, _blue);
    drawSegment(reviewCount, _green);
    drawSegment(learningCount, _red);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.newCount != newCount ||
        oldDelegate.reviewCount != reviewCount ||
        oldDelegate.learningCount != learningCount;
  }
}
