import 'dart:async';

import 'package:flutter/material.dart';

/// The interval between two ticks of a running countdown.
const _tick = Duration(seconds: 1);

/// Counts down from a fixed duration to zero, one second at a time.
///
/// The object that creates the controller also owns it and is responsible
/// for calling [dispose], which cancels a running countdown.
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
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  /// Stops ticking and keeps [remaining]. Does nothing when not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _cancel();
    notifyListeners();
  }

  /// Stops ticking and restores [remaining] to the initial duration.
  void reset() {
    _cancel();
    _remaining = _duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _onTick() {
    final next = _remaining - _tick;
    if (next <= Duration.zero) {
      _remaining = Duration.zero;
      _cancel();
    } else {
      _remaining = next;
    }
    notifyListeners();
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Shows the remaining time of [controller] as `mm:ss` with controls for it.
///
/// The controller is owned by the caller: this widget only listens to it and
/// never disposes it, so the same controller can be handed to another
/// [CountdownTimer] afterwards.
class CountdownTimer extends StatefulWidget {
  const new({required this.controller, super.key, this.onFinished});

  final CountdownController controller;

  /// Called once each time the countdown reaches zero.
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
    widget.controller.addListener(_handleTick);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleTick);
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_handleTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_format(widget.controller.remaining)),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  void _handleTick() {
    setState(() {});
    if (widget.controller.remaining > Duration.zero) {
      _finished = false;
      return;
    }
    if (_finished) {
      return;
    }
    _finished = true;
    widget.onFinished?.call();
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % Duration.secondsPerMinute).toString();
    return '$minutes:${seconds.padLeft(2, '0')}';
  }
}
