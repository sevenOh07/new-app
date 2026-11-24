import 'lesson.dart';

/// A folder on the home screen that holds lessons.
class StudyFolder {
  StudyFolder(this.name);

  final String name;
  final List<Lesson> lessons = <Lesson>[];
}
