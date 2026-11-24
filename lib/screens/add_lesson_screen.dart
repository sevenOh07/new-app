import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';

/// The clipboard-style form used to add a lesson to a folder.
class AddLessonScreen extends StatefulWidget {
  const AddLessonScreen({super.key, required this.folderNames});

  /// Folder names, in the same order as the home screen's folder list.
  final List<String> folderNames;

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

/// What the form hands back to the home screen when a lesson is saved.
class LessonDraft {
  const LessonDraft({required this.folderIndex, required this.lesson});

  final int folderIndex;
  final Lesson lesson;
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  /// Ink colours written over the clipboard paper.
  static const Color _ink = Color(0xFF2B2320);
  static const Color _fadedInk = Color(0xFF8A6D62);

  static const TextStyle _labelStyle = TextStyle(
    fontFamily: 'Doodle_Head',
    fontSize: 26,
    color: _ink,
    height: 1.1,
  );

  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  int _folderIndex = 0;
  Uint8List? _frontImage;
  Uint8List? _backImage;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool front}) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: front ? 'Choose a front image' : 'Choose a back image',
        type: FileType.image,
      );
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        if (front) {
          _frontImage = bytes;
        } else {
          _backImage = bytes;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that image.')),
      );
    }
  }

  void _save() {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();

    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write something on the front and the back!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      LessonDraft(
        folderIndex: _folderIndex,
        lesson: Lesson(
          frontText: front,
          frontImage: _frontImage,
          backText: back,
          backImage: _backImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('add_lesson_screen'),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // The clipboard sits over the same grass as the home screen.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: math.min(MediaQuery.sizeOf(context).height * 0.34, 300),
            child: Image.asset(
              'assets/images/grassy_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('add_lesson_back'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ADD',
                        style: TextStyle(
                          fontFamily: 'Doodle_Head',
                          fontSize: 40,
                          color: Colors.black,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardWidth = math.min(
                        constraints.maxWidth - 40,
                        520.0,
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Center(
                          child: SizedBox(
                            width: boardWidth,
                            child: _buildClipboard(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        key: const Key('lesson_save_button'),
                        onPressed: _save,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFE6BEBE),
                          side: const BorderSide(color: Colors.white, width: 3),
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontFamily: 'Doodle_Head',
                            fontSize: 26,
                            height: 1,
                          ),
                        ),
                        child: const Text('Save Lesson'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The clipboard art with the form written on its paper.
  Widget _buildClipboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // clipboard2_notebook.png is 221 x 300.
        final naturalHeight = width * 300 / 221;

        // The paper starts 22/221 across and 46/300 down, below the metal
        // clip. The insets keep every field written on the paper.
        final sideInset = width * 0.13;
        final topInset = width * 0.22;
        final bottomInset = width * 0.10;
        final labelWidth = math.min(76.0, width * 0.24);

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: naturalHeight),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/clipboard2_notebook.png',
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sideInset,
                  topInset,
                  sideInset,
                  bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFolderPicker(labelWidth),
                    const SizedBox(height: 16),
                    _buildLabelledField(
                      key: const Key('lesson_front_field'),
                      label: 'Front:',
                      labelWidth: labelWidth,
                      controller: _frontController,
                      hint: 'Write the front...',
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: EdgeInsets.only(left: labelWidth + 8),
                      child: _ImageAttachment(
                        key: const Key('lesson_front_image'),
                        image: _frontImage,
                        label: 'Add front image',
                        onPick: () => _pickImage(front: true),
                        onRemove: () => setState(() => _frontImage = null),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabelledField(
                      key: const Key('lesson_back_field'),
                      label: 'Back:',
                      labelWidth: labelWidth,
                      controller: _backController,
                      hint: 'Write the back...',
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: EdgeInsets.only(left: labelWidth + 8),
                      child: _ImageAttachment(
                        key: const Key('lesson_back_image'),
                        image: _backImage,
                        label: 'Add back image',
                        onPick: () => _pickImage(front: false),
                        onRemove: () => setState(() => _backImage = null),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFolderPicker(double labelWidth) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: const Text('Folder:', style: _labelStyle),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _fadedInk.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: const Key('lesson_folder_selector'),
                value: _folderIndex,
                isExpanded: true,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _fadedInk,
                ),
                dropdownColor: const Color(0xFFFBF4F4),
                borderRadius: BorderRadius.circular(16),
                style: const TextStyle(
                  fontFamily: 'Doodle_Head',
                  fontSize: 22,
                  color: _ink,
                ),
                items: [
                  for (var index = 0; index < widget.folderNames.length; index++)
                    DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        widget.folderNames[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _folderIndex = value);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabelledField({
    required Key key,
    required String label,
    required double labelWidth,
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label, style: _labelStyle),
          ),
        ),
        Expanded(
          child: TextField(
            key: key,
            controller: controller,
            minLines: 2,
            maxLines: 4,
            cursorColor: _ink,
            style: const TextStyle(
              fontFamily: 'Doodle_Head',
              fontSize: 20,
              color: _ink,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 20,
                color: Color(0xFFB4A39C),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small thumbnail with a remove button, or an "add image" action.
class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({
    super.key,
    required this.image,
    required this.label,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? image;
  final String label;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onPick,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8A6D62),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Doodle_Head',
              fontSize: 18,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              image!,
              width: 120,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFF4B3830), width: 2),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Tooltip(
                  message: 'Remove image',
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.close, size: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
