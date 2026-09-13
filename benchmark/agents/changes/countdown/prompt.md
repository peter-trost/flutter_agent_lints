Extend `lib/countdown.dart` in this Flutter app. It already implements
`CountdownController` and `CountdownTimer`, and `test/countdown_test.dart`
covers them; keep every existing test passing. Add to the public API:

```dart
class CountdownController extends ChangeNotifier {
  void addTime(Duration extra); // adds to remaining and notifies once
}
```

Behavior:

- `addTime` adds `extra` to `remaining` and notifies listeners exactly
  once. It works while running, in which case ticking continues from the
  new value; while paused; and after the countdown has finished, in which
  case `remaining` becomes `extra`, `isRunning` stays false, `start()`
  runs the countdown again, and the widget calls `onFinished` once more
  when it reaches zero.
- An `extra` that is zero or negative throws an `ArgumentError` and changes
  nothing.
- The widget gains a fourth `TextButton` labelled `+10s` that adds ten
  seconds.

Finish when `dart analyze` reports no issues and `dart format .` changes
nothing. Do not edit `analysis_options.yaml` and do not add `ignore`
comments. You may add tests of your own under `test/`.
