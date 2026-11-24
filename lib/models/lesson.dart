import 'dart:typed_data';

/// One study card: text and an optional image on each side.
class Lesson {
  const Lesson({
    required this.frontText,
    this.frontImage,
    required this.backText,
    this.backImage,
  });

  /// The prompt shown first.
  final String frontText;

  /// The image attached to the front, if any.
  final Uint8List? frontImage;

  /// The answer revealed when the card is flipped.
  final String backText;

  /// The image attached to the back, if any.
  final Uint8List? backImage;
}
