import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/lesson.dart';

/// The study screen for one folder: a stack of cards that are flipped to reveal
/// the answer and then marked as known or revisited.
///
/// Cards marked "Review again" go to the back of the queue, so every other
/// card is seen before they come back.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({
    super.key,
    required this.folderName,
    required this.lessons,
  });

  final String folderName;
  final List<Lesson> lessons;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  /// Softer ink for the "tap the card" hint over the grass.
  static const Color _softInk = Color(0xFF4B3830);

  /// back_red.png is 194 x 270, the same proportions as the mockup card.
  static const double _cardAspect = 194 / 270;

  /// The cards still waiting, in order. The one on screen is always first.
  late final List<Lesson> _queue = List<Lesson>.of(widget.lessons);

  /// Whether the current card is showing its answer side.
  bool _showingBack = false;

  /// How many cards were answered "Good" during this session.
  int _knownCount = 0;

  bool get _isDone => _queue.isEmpty;

  Lesson get _current => _queue.first;

  /// Flips the card between the prompt and the answer.
  void _flip() {
    if (_isDone) {
      return;
    }
    setState(() => _showingBack = !_showingBack);
  }

  /// Sends the current card to the end of the queue, or away entirely.
  void _grade({required bool remembered}) {
    if (_isDone) {
      return;
    }

    setState(() {
      final card = _queue.removeAt(0);
      if (remembered) {
        _knownCount++;
      } else {
        _queue.add(card);
      }
      _showingBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      key: const Key('flashcard_screen'),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Grass along the bottom, like the study mockups.
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

                      // The row below the card keeps its height even before
                      // the answer is revealed, so flipping never moves the
                      // card around.
                      final buttonHeight = math.max(
                        48.0,
                        math.min(62.0, constraints.maxHeight * 0.14),
                      );
                      final buttonGap = math.max(
                        10.0,
                        math.min(16.0, constraints.maxHeight * 0.03),
                      );
                      final bottomGap = math.max(
                        10.0,
                        math.min(24.0, constraints.maxHeight * 0.03),
                      );

                      final availableWidth = math.max(
                        0.0,
                        constraints.maxWidth - sidePadding * 2,
                      );
                      final cardAreaHeight = math.max(
                        0.0,
                        constraints.maxHeight -
                            buttonHeight -
                            buttonGap -
                            bottomGap,
                      );

                      // Pick the largest card that fits both the width and
                      // the space left above the buttons.
                      var cardWidth = math.min(availableWidth, 460.0);
                      var cardHeight = cardWidth / _cardAspect;
                      if (cardHeight > cardAreaHeight) {
                        cardHeight = cardAreaHeight;
                        cardWidth = cardHeight * _cardAspect;
                      }

                      final controlsWidth = math.min(availableWidth, 460.0);

                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: _isDone
                                  ? _buildDoneCard(cardWidth, cardHeight)
                                  : _buildCard(cardWidth, cardHeight),
                            ),
                          ),
                          SizedBox(height: buttonGap),
                          SizedBox(
                            width: controlsWidth,
                            height: buttonHeight,
                            child: _buildControls(controlsWidth),
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

  /// The back arrow and the folder being studied.
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('flashcard_exit_button'),
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

  /// The flipping card, or the congratulation card once none are left.
  Widget _buildCard(double width, double height) {
    return SizedBox(
      key: const Key('flashcard_card'),
      width: width,
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: _buildFlip,
        child: GestureDetector(
          key: ValueKey(
            '${identityHashCode(_current)}-${_showingBack ? 'back' : 'front'}',
          ),
          behavior: HitTestBehavior.opaque,
          onTap: _flip,
          child: Semantics(
            button: true,
            label: _showingBack
                ? 'Flashcard back. Tap to see the front.'
                : 'Flashcard. Tap to see the back.',
            child: _showingBack
                ? _buildBackFace(width, height)
                : _buildFrontFace(width, height),
          ),
        ),
      ),
    );
  }

  /// Turns a card over on its vertical axis as it comes and goes.
  Widget _buildFlip(Widget child, Animation<double> animation) {
    final turn = Tween<double>(
      begin: math.pi / 2,
      end: 0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(turn.value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// The question side, drawn on the green gingham card front.
  Widget _buildFrontFace(double width, double height) {
    return _buildCardFace(
      asset: 'assets/images/front_green.png',
      text: _current.frontText,
      image: _current.frontImage,
      width: width,
      height: height,
    );
  }

  /// The answer side, drawn on the red gingham card back.
  Widget _buildBackFace(double width, double height) {
    return _buildCardFace(
      asset: 'assets/images/back_red.png',
      text: _current.backText,
      image: _current.backImage,
      width: width,
      height: height,
    );
  }

  /// A card face: the gingham art with its written contents on top.
  Widget _buildCardFace({
    required String asset,
    required String text,
    required Uint8List? image,
    required double width,
    required double height,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
            _buildFaceContent(
              text: text,
              image: image,
              width: width,
              height: height,
            ),
          ],
        ),
      ),
    );
  }

  /// Shared layout for both card faces: an optional image above the text.
  Widget _buildFaceContent({
    required String text,
    required Uint8List? image,
    required double width,
    required double height,
  }) {
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
        child: Text(text, textAlign: TextAlign.center, style: textStyle),
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

  /// "Tap the card" while the front is up, then the two marking boxes.
  Widget _buildControls(double width) {
    if (_isDone) {
      return _BoxButton(
        key: const Key('flashcard_done_button'),
        label: 'Back to folders',
        fontSize: math.max(17.0, math.min(24.0, width * 0.055)),
        onTap: () => Navigator.of(context).maybePop(),
      );
    }

    if (!_showingBack) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Tap the card to see the back',
            style: TextStyle(
              fontFamily: 'Doodle_Head',
              fontSize: math.max(18.0, math.min(24.0, width * 0.055)),
              color: _softInk,
              height: 1,
            ),
          ),
        ),
      );
    }

    final fontSize = math.max(15.0, math.min(24.0, width * 0.055));

    return Row(
      children: [
        Expanded(
          child: _BoxButton(
            key: const Key('good_button'),
            label: 'Good',
            fontSize: fontSize,
            onTap: () => _grade(remembered: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BoxButton(
            key: const Key('review_again_button'),
            label: 'Review again',
            fontSize: fontSize,
            onTap: () => _grade(remembered: false),
          ),
        ),
      ],
    );
  }

  /// Shown once every card has been marked "Good".
  Widget _buildDoneCard(double width, double height) {
    return Container(
      key: const Key('flashcard_done'),
      width: width,
      height: height,
      padding: EdgeInsets.all(width * 0.10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 191, 255, 43),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All done!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: math.max(28.0, math.min(46.0, width * 0.12)),
                  color: Colors.white,
                  height: 1,
                ),
              ),
              SizedBox(height: height * 0.05),
              Text(
                'You marked $_knownCount '
                '${_knownCount == 1 ? 'card' : 'cards'} as good.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: math.max(16.0, math.min(24.0, width * 0.055)),
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rectangular, white-outlined button like the notes on the mockups.
class _BoxButton extends StatelessWidget {
  const _BoxButton({
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
