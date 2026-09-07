import 'dart:async';

import 'package:flutter/material.dart';

/// One second: both the tick interval and the amount [CountdownController]
/// subtracts from [CountdownController.remaining] on every tick.
const Duration _tick = Duration(seconds: 1);

/// Counts down from a fixed duration to zero, notifying listeners on each tick.
///
/// The controller is owned by whoever creates it: a [CountdownTimer] that is
/// given one will never dispose it, so the same controller can be handed to a
/// new widget after the old one has left the tree.
class CountdownController extends ChangeNotifier {
  /// Creates a controller whose [remaining] starts at [duration].
  CountdownController({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// The time left before the countdown finishes.
  ///
  /// Starts at the duration passed to the constructor and decreases by one
  /// second per tick while running, never going below [Duration.zero].
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking.
  ///
  /// Does nothing while already running or when [remaining] is already zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (Timer timer) => _onTick());
    notifyListeners();
  }

  /// Stops ticking, keeping [remaining] where it is.
  ///
  /// Does nothing when the countdown is not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _cancelTimer();
    notifyListeners();
  }

  /// Stops ticking and puts [remaining] back to the initial duration.
  void reset() {
    _cancelTimer();
    _remaining = _duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _onTick() {
    if (_remaining <= _tick) {
      _remaining = Duration.zero;
      _cancelTimer();
    } else {
      _remaining -= _tick;
    }
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Shows the [controller]'s remaining time as `mm:ss` plus start, pause and
/// reset buttons.
///
/// The widget rebuilds on every notification from [controller] and calls
/// [onFinished] once each time the countdown reaches zero. It never disposes
/// [controller].
class CountdownTimer extends StatefulWidget {
  /// Creates a countdown display driven by [controller].
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  /// The countdown to display and drive. Owned by the caller.
  final CountdownController controller;

  /// Called once when the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  /// Whether zero has already been reported through [CountdownTimer.onFinished]
  /// for the current run, so that it is reported exactly once.
  late bool _finished;

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
    // The controller belongs to the caller, so only the listener goes away.
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final bool atZero = widget.controller.remaining == Duration.zero;
    final bool justFinished = atZero && !_finished;
    setState(() {
      _finished = atZero;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
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
          ],
        ),
      ],
    );
  }

  String _format(Duration value) {
    final String minutes = value.inMinutes.toString().padLeft(2, '0');
    final String seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
