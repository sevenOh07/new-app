import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_screen.dart';

/// The pink splash screen shown while the app starts up.
///
/// Matches the first mockup: a soft pink background, Chiikawa in the middle
/// and a white "Loading...." caption underneath her.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, this.duration = const Duration(seconds: 5)});

  /// How long the splash stays on screen before the home screen opens.
  final Duration duration;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  /// Sampled from the mockup: RGB(230, 190, 190).
  static const Color _background = Color(0xFFE6BEBE);

  static const Duration _fadeDuration = Duration(milliseconds: 300);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _openHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openHome() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _fadeDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Sized as a fraction of the shortest side so the splash keeps its
          // proportions on both phones and wide desktop windows.
          final imageSize = math.min(width * 0.30, height * 0.32);
          final gap = math.min(width * 0.07, height * 0.05);
          final fontSize = math.min(width * 0.095, height * 0.06);

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/chiikawa_all_loading.gif',
                  width: imageSize,
                  height: imageSize,
                ),
                SizedBox(height: gap),
                Text(
                  'Loading....',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Doodle_Head',
                    fontSize: fontSize,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
