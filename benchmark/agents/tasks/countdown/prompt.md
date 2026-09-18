Implement `lib/countdown.dart` in this Flutter app. It must export exactly
this public API:

```dart
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration});

  Duration get remaining; // starts at duration
  bool get isRunning;

  void start(); // no-op while running or when remaining is zero
  void pause(); // no-op when not running
  void reset(); // stops and sets remaining back to duration
}

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  final CountdownController controller;
  final VoidCallback? onFinished;
}
```

Behavior:

- While running, `remaining` decreases by one second every second and
  listeners are notified on every tick. At zero the countdown stops,
  `isRunning` is false, and the widget calls `onFinished` exactly once.
- The widget shows `remaining` as `mm:ss` in a `Text` (65 seconds is
  `01:05`) and three `TextButton`s labelled `Start`, `Pause` and `Reset`
  that call the controller. It rebuilds on every controller notification.
- The caller owns the controller: the widget must not dispose it, and the
  same controller may be given to a new widget after the old one is gone.
  Disposing the controller cancels its timer.
- Once the widget has left the tree, controller ticks must not throw.

Finish when `dart analyze` reports no issues and `dart format .` changes
nothing. Do not edit `analysis_options.yaml` and do not add `ignore`
comments. You may add tests of your own under `test/`.
