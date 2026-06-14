import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pink_flamingo/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders the flamingo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Image), findsWidgets);
  });
}
