import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from [duration] to zero, one second at a time.
///
/// The countdown is driven by a periodic timer that only exists while the
/// controller is running. Whoever creates the controller owns it and is
/// responsible for calling [dispose].
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : assert(
        duration >= Duration.zero,
        'duration must not be negative, was $duration',
      ),
      _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown reaches zero.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking down.
  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while already running or at zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  /// Stops ticking without changing [remaining]. Does nothing when stopped.
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

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

/// Shows the [controller]'s remaining time as `mm:ss` with start, pause and
/// reset buttons.
///
/// The widget listens to the controller but never disposes it, so the same
/// controller can outlive this widget and be handed to another one.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.controller, super.key, this.onFinished});

  /// The countdown this widget displays and drives.
  final CountdownController controller;

  /// Called once each time the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late bool _wasFinished;

  @override
  void initState() {
    super.initState();
    _wasFinished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _wasFinished = widget.controller.remaining == Duration.zero;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final bool isFinished = widget.controller.remaining == Duration.zero;
    if (isFinished && !_wasFinished) {
      widget.onFinished?.call();
    }
    _wasFinished = isFinished;
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
          ],
        ),
      ],
    );
  }
}
