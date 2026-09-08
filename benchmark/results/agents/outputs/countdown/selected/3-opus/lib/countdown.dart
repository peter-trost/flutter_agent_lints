import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from a fixed duration to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose]; widgets that render it never do.
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : assert(duration >= Duration.zero, 'duration must not be negative'),
      _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown finishes. Starts at the duration the
  /// controller was created with and never goes below [Duration.zero].
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while already running or once [remaining]
  /// has reached zero.
  void start() {
    if (_timer != null || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, _onTick);
  }

  /// Stops ticking, keeping [remaining] where it is. Does nothing when the
  /// countdown is not running.
  void pause() {
    final timer = _timer;
    if (timer == null) {
      return;
    }
    timer.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Stops ticking and puts [remaining] back to the initial duration.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _remaining = _duration;
    notifyListeners();
  }

  void _onTick(Timer timer) {
    final next = _remaining - _tick;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
      timer.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// Shows the remaining time of a [CountdownController] as `mm:ss` along with
/// start, pause and reset buttons.
///
/// The widget does not own [controller]: it neither disposes it nor prevents
/// it from being handed to another [CountdownTimer] later.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  /// The countdown to display and drive.
  final CountdownController controller;

  /// Called once each time the countdown reaches zero while this widget is
  /// listening.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.controller.remaining;
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      _remaining = widget.controller.remaining;
      widget.controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final previous = _remaining;
    setState(() {
      _remaining = widget.controller.remaining;
    });
    if (previous > Duration.zero && _remaining == Duration.zero) {
      widget.onFinished?.call();
    }
  }

  String _format(Duration remaining) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(_format(_remaining)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(onPressed: controller.start, child: const Text('Start')),
            TextButton(onPressed: controller.pause, child: const Text('Pause')),
            TextButton(onPressed: controller.reset, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }
}
