import 'dart:async';

import 'package:flutter/material.dart';

/// Drives a countdown from [duration] down to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose].
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  static const Duration _tickInterval = Duration(seconds: 1);

  final Duration _duration;
  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown finishes. Starts at the duration the
  /// controller was created with.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while already running or once [remaining]
  /// has reached zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tickInterval, _tick);
    notifyListeners();
  }

  /// Stops ticking, keeping [remaining] where it is. Does nothing when the
  /// countdown is not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _stop();
    notifyListeners();
  }

  /// Adds [extra] to [remaining] and notifies listeners once.
  ///
  /// Works while the countdown is running, in which case ticking carries on
  /// from the new value, while it is paused, and after it has finished, in
  /// which case [start] can run it again.
  ///
  /// Throws an [ArgumentError] when [extra] is zero or negative, leaving the
  /// countdown untouched.
  void addTime(Duration extra) {
    if (extra <= Duration.zero) {
      throw ArgumentError.value(extra, 'extra', 'must be greater than zero');
    }
    _remaining += extra;
    notifyListeners();
  }

  /// Stops ticking and sets [remaining] back to the initial duration.
  void reset() {
    _stop();
    _remaining = _duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _tick(Timer timer) {
    final Duration next = _remaining - _tickInterval;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
      _stop();
    }
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Shows the [controller]'s remaining time as `mm:ss` along with start, pause,
/// reset and `+10s` buttons.
///
/// The widget never disposes the [controller]; the caller keeps ownership and
/// may hand the same controller to another [CountdownTimer] later.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  final CountdownController controller;

  /// Called once when the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  static const Duration _extraTime = Duration(seconds: 10);

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _finished = widget.controller.remaining == Duration.zero;
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final bool atZero = widget.controller.remaining == Duration.zero;
    if (atZero && !_finished) {
      _finished = true;
      widget.onFinished?.call();
    } else if (!atZero) {
      _finished = false;
    }
  }

  void _handleAddTimePressed() {
    widget.controller.addTime(_extraTime);
  }

  static String _format(Duration remaining) {
    final String minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final String seconds = (remaining.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(_format(widget.controller.remaining)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(
              onPressed: widget.controller.start,
              child: const Text('Start'),
            ),
            TextButton(
              onPressed: widget.controller.pause,
              child: const Text('Pause'),
            ),
            TextButton(
              onPressed: widget.controller.reset,
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: _handleAddTimePressed,
              child: const Text('+10s'),
            ),
          ],
        ),
      ],
    );
  }
}
