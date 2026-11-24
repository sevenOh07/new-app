import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiikawa_app/main.dart';

void main() {
  testWidgets('measure', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    debugPrint('message rect: ${tester.getRect(find.text("There's nothing here..."))}');
    debugPrint('chiikawa rect: ${tester.getRect(find.image(const AssetImage("assets/images/chiikawa_confused.png")))}');
  });
}
