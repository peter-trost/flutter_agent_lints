import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from a fixed duration to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose], which also cancels a running countdown.
class CountdownController extends ChangeNotifier {
  new({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  static const _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// Time left before the countdown reaches zero.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking; does nothing while running or once [remaining] is zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  /// Stops ticking and keeps [remaining]; does nothing when not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _cancelTimer();
    notifyListeners();
  }

  /// Stops ticking and restores [remaining] to the configured duration.
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
    final next = _remaining - _tick;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
      _cancelTimer();
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
/// The controller is owned by the caller: this widget never disposes it, so the
/// same controller can be handed to another [CountdownTimer] afterwards.
class CountdownTimer extends StatefulWidget {
  const new({required this.controller, super.key, this.onFinished});

  final CountdownController controller;

  /// Called once each time the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late bool _finished;

  @override
  void initState() {
    super.initState();
    _finished = _isFinished(widget.controller);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _finished = _isFinished(widget.controller);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_format(controller.remaining)),
        TextButton(onPressed: controller.start, child: const Text('Start')),
        TextButton(onPressed: controller.pause, child: const Text('Pause')),
        TextButton(onPressed: controller.reset, child: const Text('Reset')),
      ],
    );
  }

  bool _isFinished(CountdownController controller) =>
      !controller.isRunning && controller.remaining == Duration.zero;

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final finished = _isFinished(widget.controller);
    final justFinished = finished && !_finished;
    setState(() {
      _finished = finished;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
