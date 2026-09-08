import 'dart:async';

import 'package:flutter/material.dart';

const _tick = Duration(seconds: 1);

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Counts down from the given duration to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose], which cancels the running timer.
class CountdownController extends ChangeNotifier {
  new({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  Duration get remaining => _remaining;

  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while running or once [remaining] is zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, _onTick);
  }

  /// Stops ticking, keeping [remaining]. Does nothing when not running.
  void pause() {
    _cancelTimer();
  }

  /// Stops ticking and restores [remaining] to the initial duration.
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

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTick(Timer timer) {
    final next = _remaining - _tick;
    _remaining = next < Duration.zero ? Duration.zero : next;
    if (_remaining == Duration.zero) {
      _cancelTimer();
    }
    notifyListeners();
  }
}

/// Shows the remaining time of [controller] as `mm:ss` with controls for it.
///
/// The widget never disposes [controller]; the caller keeps that ownership.
class CountdownTimer extends StatefulWidget {
  const new({required this.controller, super.key, this.onFinished});

  final CountdownController controller;

  /// Called once when the countdown reaches zero while this widget is mounted.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  var _finished = false;

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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatDuration(controller.remaining)),
        TextButton(onPressed: controller.start, child: const Text('Start')),
        TextButton(onPressed: controller.pause, child: const Text('Pause')),
        TextButton(onPressed: controller.reset, child: const Text('Reset')),
      ],
    );
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final finished = widget.controller.remaining == Duration.zero;
    if (finished && !_finished) {
      widget.onFinished?.call();
    }
    _finished = finished;
  }
}
