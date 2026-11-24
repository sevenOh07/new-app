import 'package:flutter/material.dart';

/// The pink shared by the app's panels and dialogs.
const Color _panelPink = Color(0xFFE6BEBE);

/// A small pink dialog that asks the member to confirm a destructive action.
///
/// Pops with `true` when the action is confirmed and `false` otherwise.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelKey,
    this.confirmKey,
  });

  /// The heading, such as "Delete Folder".
  final String title;

  /// What is about to be deleted.
  final String message;

  /// The text on the button that goes through with the action.
  final String confirmLabel;

  final Key? cancelKey;
  final Key? confirmKey;

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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Doodle_Head',
                fontSize: 20,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    key: cancelKey,
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    key: confirmKey,
                    label: confirmLabel,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A white-outlined pill button inside [ConfirmDialog].
class _DialogButton extends StatelessWidget {
  const _DialogButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          side: const BorderSide(color: Colors.white, width: 3),
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
