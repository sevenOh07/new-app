/// How a card is doing, as shown in the Status drawer.
enum CardStatus {
  /// The card has never been studied.
  newCard,

  /// The card was last answered correctly.
  review,

  /// The card was last answered wrong, so it is still being learned.
  learning,
}

/// The study history for one [Lesson], kept outside the lesson itself so the
/// lesson stays a simple, immutable value.
class LessonProgress {
  /// How many times the card has been studied.
  int reviewCount = 0;

  /// How many of those reviews were correct (or marked "Good").
  int correctCount = 0;

  /// The most recent review, if the card has been studied.
  DateTime? lastReviewedAt;

  /// Whether the most recent review was correct.
  bool lastReviewCorrect = false;

  /// Which group the card belongs to in the Status drawer.
  CardStatus get status {
    if (reviewCount == 0) {
      return CardStatus.newCard;
    }
    return lastReviewCorrect ? CardStatus.review : CardStatus.learning;
  }

  /// Records one study result for the card.
  void record({required bool correct, DateTime? at}) {
    reviewCount++;
    if (correct) {
      correctCount++;
    }
    lastReviewCorrect = correct;
    lastReviewedAt = at ?? DateTime.now();
  }
}
