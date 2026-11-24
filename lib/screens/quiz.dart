import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lesson.dart';

/// The multiple-choice study mode for one folder.
///
/// Each question is a lesson's front, and the answers are that lesson's back
/// plus the backs of other lessons in the same folder. Answering reveals
/// whether the choice was right before moving on.
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.folderName,
    required this.lessons,
  });

  final String folderName;
  final List<Lesson> lessons;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const Color _ink = Color(0xFF2B2320);
  static const Color _softInk = Color(0xFF4B3830);
  static const Color _rightGreen = Color(0xFF4F8A2F);
  static const Color _wrongRed = Color(0xFFC0504D);

  /// front_green.png is 194 x 270.
  static const double _cardAspect = 194 / 270;

  /// The lessons in quiz order.
  late final List<Lesson> _questions = List<Lesson>.of(widget.lessons)
    ..shuffle();

  /// The choices for the question currently on screen.
  late List<String> _options = _questions.isEmpty
      ? const <String>[]
      : _makeOptions(_questions.first);

  int _index = 0;
  int _correctCount = 0;

  /// The answer the member tapped, or null before they answer.
  String? _selected;

  bool get _isDone => _index >= _questions.length;

  bool get _answered => _selected != null;

  Lesson get _current => _questions[_index];

  /// The correct answer plus up to three answers borrowed from other cards.
  List<String> _makeOptions(Lesson lesson) {
    final options = <String>[lesson.backText];

    final distractors = <String>{
      for (final other in widget.lessons)
        if (other.backText != lesson.backText) other.backText,
    }.toList()..shuffle();

    for (final distractor in distractors) {
      if (options.length >= 4) {
        break;
      }
      options.add(distractor);
    }

    options.shuffle();
    return options;
  }

  void _select(String option) {
    if (_answered || _isDone) {
      return;
    }

    setState(() {
      _selected = option;
      if (option == _current.backText) {
        _correctCount++;
      }
    });
  }

  void _next() {
    if (!_answered) {
      return;
    }

    setState(() {
      _selected = null;
      if (_index + 1 >= _questions.length) {
        _index = _questions.length;
        _options = const <String>[];
      } else {
        _index++;
        _options = _makeOptions(_current);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      key: const Key('quiz_screen'),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight * 0.46,
            child: Image.asset(
              'assets/images/grassy_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sidePadding = math.max(
                        12.0,
                        math.min(32.0, constraints.maxWidth * 0.05),
                      );
                      final availableWidth = math.max(
                        0.0,
                        constraints.maxWidth - sidePadding * 2,
                      );
                      final controlsWidth = math.min(availableWidth, 460.0);

                      final controlHeight = math.max(
                        44.0,
                        math.min(62.0, constraints.maxHeight * 0.14),
                      );
                      final optionGap = math.max(
                        5.0,
                        math.min(10.0, constraints.maxHeight * 0.012),
                      );
                      final cardGap = math.max(
                        8.0,
                        math.min(14.0, constraints.maxHeight * 0.02),
                      );
                      final bottomGap = math.max(
                        8.0,
                        math.min(20.0, constraints.maxHeight * 0.025),
                      );

                      // Leave room for the question card, then fit as many
                      // answer notes as the remaining height allows.
                      final reservedBelow =
                          controlHeight + cardGap + bottomGap * 2;
                      final optionCount = _isDone ? 0 : _options.length;
                      final forOptions = constraints.maxHeight - reservedBelow;
                      final optionHeight = optionCount == 0
                          ? 0.0
                          : math.max(
                              30.0,
                              math.min(
                                54.0,
                                (forOptions -
                                        (optionCount - 1) * optionGap -
                                        60) /
                                    optionCount,
                              ),
                            );
                      final optionsHeight = optionCount == 0
                          ? 0.0
                          : optionCount * optionHeight +
                                (optionCount - 1) * optionGap;

                      final cardAreaHeight = math.max(
                        0.0,
                        constraints.maxHeight - optionsHeight - reservedBelow,
                      );

                      var cardWidth = math.min(availableWidth, 460.0);
                      var cardHeight = cardWidth / _cardAspect;
                      if (cardHeight > cardAreaHeight) {
                        cardHeight = cardAreaHeight;
                        cardWidth = cardHeight * _cardAspect;
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: _isDone
                                  ? _buildResult(cardWidth, cardHeight)
                                  : _buildQuestionCard(cardWidth, cardHeight),
                            ),
                          ),
                          if (!_isDone) ...[
                            SizedBox(height: cardGap),
                            SizedBox(
                              width: controlsWidth,
                              child: _buildOptions(
                                controlsWidth,
                                optionHeight,
                                optionGap,
                              ),
                            ),
                          ],
                          SizedBox(height: bottomGap),
                          SizedBox(
                            width: controlsWidth,
                            height: controlHeight,
                            child: _buildControl(controlsWidth),
                          ),
                          SizedBox(height: bottomGap),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('quiz_exit_button'),
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

  /// The prompt card, in the same green gingham as a flashcard front.
  Widget _buildQuestionCard(double width, double height) {
    return Container(
      key: const Key('quiz_question_card'),
      width: width,
      height: height,
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/front_green.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
            _buildQuestionContent(width, height),
          ],
        ),
      ),
    );
  }

  /// The front text (and image, if any) written on the question card.
  Widget _buildQuestionContent(double width, double height) {
    final lesson = _current;
    final image = lesson.frontImage;
    final inset = width * 0.11 + 3;

    final textStyle = TextStyle(
      fontFamily: 'Doodle_Head',
      fontSize: math.max(16.0, math.min(28.0, width * 0.065)),
      color: Colors.white,
      height: 1.25,
      shadows: [
        Shadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 5),
      ],
    );

    final textWidget = Center(
      child: SingleChildScrollView(
        child: Text(
          lesson.frontText,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );

    if (image == null) {
      return Padding(padding: EdgeInsets.all(inset), child: textWidget);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, inset, inset, inset * 0.75),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: height * 0.035),
          Expanded(flex: 4, child: textWidget),
        ],
      ),
    );
  }

  /// The answer notes under the question.
  Widget _buildOptions(double width, double optionHeight, double gap) {
    return Column(
      children: [
        for (var index = 0; index < _options.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          SizedBox(
            height: optionHeight,
            child: _buildOption(width, _options[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildOption(double width, String option) {
    final isCorrect = option == _current.backText;
    final isSelected = option == _selected;
    final showAnswer = _answered;

    final Color? tint;
    final Color? outline;
    if (!showAnswer) {
      tint = null;
      outline = null;
    } else if (isCorrect) {
      tint = _rightGreen.withValues(alpha: 0.28);
      outline = _rightGreen;
    } else if (isSelected) {
      tint = _wrongRed.withValues(alpha: 0.24);
      outline = _wrongRed;
    } else {
      tint = null;
      outline = null;
    }

    return Semantics(
      button: true,
      enabled: !showAnswer,
      label: 'Answer: $option',
      child: GestureDetector(
        key: ValueKey('quiz_option_$option'),
        behavior: HitTestBehavior.opaque,
        onTap: showAnswer ? null : () => _select(option),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: showAnswer && !isCorrect && !isSelected ? 0.6 : 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: outline == null
                  ? null
                  : Border.all(color: outline, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/choices_note.png',
                    fit: BoxFit.fill,
                  ),
                  if (tint != null) ColoredBox(color: tint),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, width * 0.085 + 10, 4),
                    child: Center(
                      child: Text(
                        option,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Doodle_Head',
                          fontSize: math.max(
                            13.0,
                            math.min(20.0, width * 0.05),
                          ),
                          color: _ink,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A hint before answering, then Next, then the way home.
  Widget _buildControl(double width) {
    final fontSize = math.max(15.0, math.min(24.0, width * 0.055));

    if (_isDone) {
      return _QuizButton(
        key: const Key('quiz_done_button'),
        label: 'Back to folders',
        fontSize: fontSize,
        onTap: () => Navigator.of(context).maybePop(),
      );
    }

    if (!_answered) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Choose the correct answer',
            style: TextStyle(
              fontFamily: 'Doodle_Head',
              fontSize: math.max(17.0, math.min(24.0, width * 0.055)),
              color: _softInk,
              height: 1,
            ),
          ),
        ),
      );
    }

    final isLast = _index + 1 >= _questions.length;

    return _QuizButton(
      key: const Key('quiz_next_button'),
      label: isLast ? 'See results' : 'Next',
      fontSize: fontSize,
      onTap: _next,
    );
  }

  /// The score shown after the final question.
  Widget _buildResult(double width, double height) {
    // A score of 70% or more counts as passing, and earns a happy dance.
    final passed =
        _questions.isNotEmpty && _correctCount / _questions.length >= 0.7;
    final message = passed
        ? 'Good job! You passed!'
        : "It's not the end! try again!";
    final celebration = passed
        ? 'assets/images/dance_dance.gif'
        : 'assets/images/chiikawa_sad.gif';

    return SizedBox(
      key: const Key('quiz_result'),
      width: width,
      height: height,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: math.max(24.0, math.min(42.0, width * 0.1)),
                  color: _softInk,
                  height: 1.1,
                ),
              ),
              SizedBox(height: height * 0.04),
              Text(
                'You got $_correctCount out of ${_questions.length} right.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: math.max(16.0, math.min(24.0, width * 0.055)),
                  color: _softInk,
                  height: 1.2,
                ),
              ),
              SizedBox(height: height * 0.02),
              SizedBox(
                key: Key(passed ? 'quiz_result_happy' : 'quiz_result_sad'),
                height: math.max(56.0, height * 0.42),
                width: double.infinity,
                child: Image.asset(
                  celebration,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

/// A rectangular, white-outlined button in the folder's palette.
class _QuizButton extends StatelessWidget {
  const _QuizButton({
    super.key,
    required this.label,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color.fromARGB(255, 255, 206, 45),
          side: const BorderSide(color: Colors.white, width: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: TextStyle(
            fontFamily: 'Doodle_Head',
            fontSize: fontSize,
            height: 1,
          ),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}
