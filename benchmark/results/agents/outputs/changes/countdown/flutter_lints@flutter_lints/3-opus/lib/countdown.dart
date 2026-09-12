import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from [duration] to zero, one second at a time.
///
/// The object that creates a controller owns it and is responsible for
/// calling [dispose]; [CountdownTimer] never disposes the controller it is
/// given.
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// The time left before the countdown finishes.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking.
  ///
  /// Does nothing while the countdown is already running or when there is no
  /// time left.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, _onTick);
  }

  /// Stops ticking, keeping [remaining] where it is.
  ///
  /// Does nothing when the countdown is not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _stop();
  }

  /// Adds [extra] to [remaining], notifying listeners once.
  ///
  /// Works while running, in which case ticking carries on from the new
  /// value, while paused, and after the countdown has finished, in which case
  /// [remaining] becomes [extra] and [start] runs the countdown again.
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

  void _onTick(Timer timer) {
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
}

/// Displays the [controller]'s remaining time as `mm:ss` with start, pause,
/// reset and `+10s` buttons.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  /// The countdown to display and drive. Owned by the caller.
  final CountdownController controller;

  /// Called once each time the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  static const Duration _bonus = Duration(seconds: 10);

  bool _finishedReported = false;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.controller);
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleUpdate);
      _subscribe(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleUpdate);
    super.dispose();
  }

  void _subscribe(CountdownController controller) {
    _finishedReported = controller.remaining == Duration.zero;
    controller.addListener(_handleUpdate);
  }

  void _handleUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (widget.controller.remaining == Duration.zero) {
      if (!_finishedReported) {
        _finishedReported = true;
        widget.onFinished?.call();
      }
    } else {
      _finishedReported = false;
    }
  }

  static String _format(Duration remaining) {
    final String minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final String seconds = (remaining.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final CountdownController controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(_format(controller.remaining)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(onPressed: controller.start, child: const Text('Start')),
            TextButton(onPressed: controller.pause, child: const Text('Pause')),
            TextButton(onPressed: controller.reset, child: const Text('Reset')),
            TextButton(
              onPressed: () => controller.addTime(_bonus),
              child: const Text('+10s'),
            ),
          ],
        ),
      ],
    );
  }
}
