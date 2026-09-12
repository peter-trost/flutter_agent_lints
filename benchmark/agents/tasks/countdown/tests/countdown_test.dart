import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/countdown.dart';

Widget _app(CountdownController controller, {VoidCallback? onFinished}) =>
    MaterialApp(
      home: Scaffold(
        body: CountdownTimer(controller: controller, onFinished: onFinished),
      ),
    );

void main() {
  testWidgets('shows the remaining time as mm:ss', (tester) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 65),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    expect(find.text('01:05'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Start'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Pause'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Reset'), findsOneWidget);
  });

  testWidgets('start ticks once per second and the widget follows', (
    tester,
  ) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 65),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(controller.isRunning, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:04'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('01:00'), findsOneWidget);
    controller.pause();
  });

  testWidgets('pause holds and reset restores', (tester) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 10),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 3));
    expect(controller.isRunning, isFalse);
    expect(controller.remaining, const Duration(seconds: 7));
    expect(find.text('00:07'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(controller.remaining, const Duration(seconds: 10));
    expect(find.text('00:10'), findsOneWidget);
  });

  testWidgets('finishes at zero and calls onFinished once', (tester) async {
    var finished = 0;
    final controller = CountdownController(
      duration: const Duration(seconds: 2),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller, onFinished: () => finished++));
    controller.start();
    await tester.pump(const Duration(seconds: 3));
    expect(controller.remaining, Duration.zero);
    expect(controller.isRunning, isFalse);
    expect(find.text('00:00'), findsOneWidget);
    expect(finished, 1);
    controller.start();
    await tester.pump(const Duration(seconds: 2));
    expect(finished, 1);
    expect(controller.isRunning, isFalse);
  });

  testWidgets('start while running and pause while stopped are no-ops', (
    tester,
  ) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);
    controller.pause();
    expect(controller.isRunning, isFalse);
    controller
      ..start()
      ..start();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.remaining, const Duration(seconds: 4));
    controller.pause();
  });

  testWidgets('ticks after the widget is gone do not throw', (tester) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    controller.start();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(controller.remaining, const Duration(seconds: 2));
    await tester.pumpWidget(_app(controller));
    expect(find.text('00:02'), findsOneWidget);
    controller.pause();
  });

  testWidgets('disposing the controller cancels its timer', (tester) async {
    final controller = CountdownController(duration: const Duration(seconds: 5))
      ..start();
    await tester.pump(const Duration(seconds: 1));
    controller.dispose();
    await tester.pump(const Duration(seconds: 5));
  });
}
