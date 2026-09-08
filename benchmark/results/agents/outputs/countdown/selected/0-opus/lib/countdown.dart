import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from [Duration] to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose]; a [CountdownTimer] built with it never does.
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : assert(duration >= Duration.zero, 'duration must not be negative'),
      _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown finishes, starting at the duration the
  /// controller was created with.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking.
  ///
  /// Does nothing while already running, or once [remaining] has reached zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, _onTick);
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

  void _onTick(Timer timer) {
    final Duration next = _remaining - _tick;
    if (next <= Duration.zero) {
      _remaining = Duration.zero;
      _cancelTimer();
    } else {
      _remaining = next;
    }
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Shows the [controller]'s remaining time as `mm:ss` with start, pause and
/// reset buttons.
///
/// The widget listens to [controller] but never disposes it, so the same
/// controller can be handed to another [CountdownTimer] later on.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.controller, super.key, this.onFinished});

  final CountdownController controller;

  /// Called once each time the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  /// Whether [CountdownTimer.onFinished] has already been reported for the
  /// current run, so that further notifications at zero stay silent.
  late bool _finished;

  @override
  void initState() {
    super.initState();
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _finished = widget.controller.remaining == Duration.zero;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final bool reachedZero = widget.controller.remaining == Duration.zero;
    final bool shouldReport = reachedZero && !_finished;
    setState(() {
      _finished = reachedZero;
    });
    if (shouldReport) {
      widget.onFinished?.call();
    }
  }

  static String _format(Duration value) {
    final int totalSeconds = value.inSeconds;
    final String minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');
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
          ],
        ),
      ],
    );
  }
}
