import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from [duration] to zero, one second at a time.
///
/// The object that creates a controller owns it and is responsible for
/// calling [dispose]; widgets that render it never do.
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown reaches zero.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking down.
  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while running or once [remaining] is zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, _onTick);
    notifyListeners();
  }

  /// Stops ticking, keeping [remaining]. Does nothing when not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _cancelTimer();
    notifyListeners();
  }

  /// Stops ticking and restores [remaining] to the original duration.
  void reset() {
    _cancelTimer();
    _remaining = _duration;
    notifyListeners();
  }

  void _onTick(Timer timer) {
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

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}

/// Shows the remaining time of a [CountdownController] as `mm:ss` alongside
/// start, pause and reset buttons.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.controller, super.key, this.onFinished});

  /// The countdown to display and drive. Owned by the caller.
  final CountdownController controller;

  /// Called once each time the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _attach(widget.controller);
    }
  }

  @override
  void dispose() {
    // The controller belongs to the caller, so only the listener goes away.
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _attach(CountdownController controller) {
    // An already finished controller must not fire [onFinished] again.
    _finishedNotified = controller.remaining == Duration.zero;
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    setState(() {});
    final bool finished = widget.controller.remaining == Duration.zero;
    if (finished && !_finishedNotified) {
      _finishedNotified = true;
      widget.onFinished?.call();
    } else if (!finished) {
      _finishedNotified = false;
    }
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
          ],
        ),
      ],
    );
  }
}
