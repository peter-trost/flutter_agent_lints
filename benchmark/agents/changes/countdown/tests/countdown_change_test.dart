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
  testWidgets('the +10s button adds ten seconds while paused', (tester) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 10),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    await tester.tap(find.widgetWithText(TextButton, '+10s'));
    await tester.pump();
    expect(controller.remaining, const Duration(seconds: 20));
    expect(controller.isRunning, isFalse);
    expect(find.text('00:20'), findsOneWidget);
  });

  testWidgets('addTime while running keeps ticking from the new value', (
    tester,
  ) async {
    final controller = CountdownController(
      duration: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));
    controller.start();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:03'), findsOneWidget);
    controller.addTime(const Duration(seconds: 10));
    await tester.pump();
    expect(find.text('00:13'), findsOneWidget);
    expect(controller.isRunning, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:12'), findsOneWidget);
    controller.pause();
  });

  testWidgets('after finishing, addTime and start run it again', (
    tester,
  ) async {
    var finished = 0;
    final controller = CountdownController(
      duration: const Duration(seconds: 2),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller, onFinished: () => finished++));
    controller.start();
    await tester.pump(const Duration(seconds: 2));
    expect(finished, 1);
    expect(controller.remaining, Duration.zero);

    controller.addTime(const Duration(seconds: 3));
    await tester.pump();
    expect(controller.remaining, const Duration(seconds: 3));
    expect(controller.isRunning, isFalse);
    expect(finished, 1);

    controller.start();
    await tester.pump(const Duration(seconds: 3));
    expect(finished, 2);
    expect(controller.isRunning, isFalse);
  });

  test('addTime notifies exactly once', () {
    var notifications = 0;
    final controller = CountdownController(
      duration: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);
    controller
      ..addListener(() => notifications++)
      ..addTime(const Duration(seconds: 1));
    expect(notifications, 1);
    expect(controller.remaining, const Duration(seconds: 6));
  });

  test('a non-positive extra throws and changes nothing', () {
    final controller = CountdownController(
      duration: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);
    expect(() => controller.addTime(Duration.zero), throwsArgumentError);
    expect(
      () => controller.addTime(const Duration(seconds: -1)),
      throwsArgumentError,
    );
    expect(controller.remaining, const Duration(seconds: 5));
  });
}
