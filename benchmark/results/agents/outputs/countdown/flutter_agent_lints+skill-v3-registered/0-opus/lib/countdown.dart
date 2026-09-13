import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from a fixed duration, one second at a time.
///
/// The object that creates the controller also owns it: a
/// CountdownTimer widget never disposes the controller it is given, so one
/// controller can outlive the widgets that display it.
class CountdownController extends ChangeNotifier {
  new({required this.duration}) : _remaining = duration;

  static const _tick = Duration(seconds: 1);

  /// The value remaining is set to by the constructor and by reset.
  final Duration duration;

  Duration _remaining;
  Timer? _timer;

  Duration get remaining => _remaining;

  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while already running or at zero.
  void start() {
    if (_timer != null || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, _onTick);
  }

  /// Stops ticking, keeping the remaining time. Does nothing when stopped.
  void pause() {
    _cancel();
  }

  /// Stops ticking and restores the full duration.
  void reset() {
    _cancel();
    _remaining = duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    final next = _remaining - _tick;
    if (next > Duration.zero) {
      _remaining = next;
    } else {
      _remaining = Duration.zero;
      _cancel();
    }
    notifyListeners();
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Displays the remaining time of a controller as `mm:ss`, with buttons
/// driving it.
class CountdownTimer extends StatefulWidget {
  const new({required this.controller, this.onFinished, super.key});

  final CountdownController controller;

  /// Called once each time the countdown reaches zero while this widget is
  /// in the tree.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  /// Whether zero has already been reported for the current controller, so
  /// that further notifications at zero do not report it again.
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _listenTo(widget.controller);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _listenTo(widget.controller);
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
        Text(_formatRemaining(controller.remaining)),
        TextButton(onPressed: controller.start, child: const Text('Start')),
        TextButton(onPressed: controller.pause, child: const Text('Pause')),
        TextButton(onPressed: controller.reset, child: const Text('Reset')),
      ],
    );
  }

  void _listenTo(CountdownController controller) {
    // A controller handed over at zero has already finished; reaching zero
    // again takes a reset first, which clears the flag.
    _finished = controller.remaining == Duration.zero;
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final isFinished = widget.controller.remaining == Duration.zero;
    final justFinished = isFinished && !_finished;
    setState(() {
      _finished = isFinished;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }
}

String _formatRemaining(Duration remaining) {
  final minutes = remaining.inMinutes.toString().padLeft(2, '0');
  final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
