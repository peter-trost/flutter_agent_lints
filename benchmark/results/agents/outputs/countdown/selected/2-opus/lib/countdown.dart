import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from [duration] to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose]; a [CountdownTimer] built with it never does.
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : assert(
        !duration.isNegative,
        'duration must not be negative, was $duration',
      ),
      _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown finishes. Starts at the duration the
  /// controller was created with and never goes below zero.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking down.
  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while already running or once [remaining]
  /// has reached zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (Timer timer) => _onTick());
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

  /// Stops ticking and puts [remaining] back to the original duration.
  void reset() {
    _stop();
    _remaining = _duration;
    notifyListeners();
  }

  void _onTick() {
    final Duration next = _remaining - _tick;
    if (next <= Duration.zero) {
      _remaining = Duration.zero;
      _stop();
    } else {
      _remaining = next;
    }
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

/// Shows the remaining time of a [CountdownController] as `mm:ss` along with
/// buttons driving it.
///
/// The widget only listens to [controller]; it never disposes it, so the same
/// controller can be handed to another [CountdownTimer] afterwards.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  /// The countdown this widget displays and controls.
  final CountdownController controller;

  /// Called once, when the countdown reaches zero while this widget is in the
  /// tree.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  /// Whether the current run to zero has already been reported, so that a
  /// controller sitting at zero does not fire [CountdownTimer.onFinished]
  /// again on every later notification.
  late bool _finished;

  @override
  void initState() {
    super.initState();
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
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
    final bool reachedZero =
        !_finished && widget.controller.remaining == Duration.zero;
    _finished = widget.controller.remaining == Duration.zero;
    setState(() {});
    if (reachedZero) {
      widget.onFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(_formatDuration(widget.controller.remaining)),
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
    );
  }
}

String _formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final String minutes = (totalSeconds ~/ Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
  final String seconds = (totalSeconds % Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds';
}
