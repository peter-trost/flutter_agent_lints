import 'dart:async';

import 'package:flutter/material.dart';

/// Counts down from [duration] to zero, one second at a time.
///
/// The object that creates the controller owns it and is responsible for
/// calling [dispose]; a [CountdownTimer] using it will never dispose it.
class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  static const Duration _tick = Duration(seconds: 1);

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  /// The time left before the countdown finishes.
  ///
  /// Starts out at the `duration` the controller was created with.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking down.
  bool get isRunning => _timer != null;

  /// Starts ticking.
  ///
  /// Does nothing when the countdown is already running or has finished.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  /// Stops ticking, keeping [remaining] where it is.
  ///
  /// Does nothing when the countdown is not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _cancel();
    notifyListeners();
  }

  /// Stops ticking and puts [remaining] back to the original duration.
  void reset() {
    _cancel();
    _remaining = _duration;
    notifyListeners();
  }

  void _onTick() {
    final Duration next = _remaining - _tick;
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

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}

/// Displays the [controller]'s remaining time and controls for it.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.controller, super.key, this.onFinished});

  /// The countdown to display. Owned by the caller, never disposed here.
  final CountdownController controller;

  /// Called once, when the countdown reaches zero.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _finished = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (widget.controller.remaining == Duration.zero && !_finished) {
      _finished = true;
      widget.onFinished?.call();
    }
  }

  static String _format(Duration remaining) {
    final int totalSeconds = remaining.inSeconds;
    final String minutes = '${totalSeconds ~/ 60}'.padLeft(2, '0');
    final String seconds = '${totalSeconds % 60}'.padLeft(2, '0');
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
