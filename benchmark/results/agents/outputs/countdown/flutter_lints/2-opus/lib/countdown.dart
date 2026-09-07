import 'dart:async';

import 'package:flutter/material.dart';

const Duration _tick = Duration(seconds: 1);

/// Counts down from [duration] to zero, one second at a time.
///
/// The countdown is driven by a timer that is owned by this controller and
/// cancelled when the controller is disposed. Listeners are notified on every
/// tick as well as whenever the running state changes.
class CountdownController extends ChangeNotifier {
  /// Creates a controller whose [remaining] starts at [duration].
  CountdownController({required this.duration}) : _remaining = duration;

  /// The value [remaining] starts at and is restored to by [reset].
  final Duration duration;

  Duration _remaining;
  Timer? _timer;

  /// The time left before the countdown finishes.
  Duration get remaining => _remaining;

  /// Whether the countdown is currently ticking.
  bool get isRunning => _timer != null;

  /// Starts ticking.
  ///
  /// Does nothing while already running or when [remaining] is already zero.
  void start() {
    if (isRunning || _remaining <= Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  /// Stops ticking, keeping [remaining] where it is.
  ///
  /// Does nothing when not running.
  void pause() {
    if (!isRunning) {
      return;
    }
    _cancel();
    notifyListeners();
  }

  /// Stops ticking and restores [remaining] to [duration].
  void reset() {
    _cancel();
    _remaining = duration;
    notifyListeners();
  }

  void _onTick() {
    _remaining = _remaining - _tick;
    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _cancel();
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

/// Displays the [controller]'s remaining time as `mm:ss` with start, pause and
/// reset buttons.
///
/// The controller is owned by the caller: this widget never disposes it, and
/// the same controller can be handed to another [CountdownTimer] afterwards.
class CountdownTimer extends StatefulWidget {
  /// Creates a countdown display driven by [controller].
  const CountdownTimer({required this.controller, super.key, this.onFinished});

  /// The countdown to display and control.
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
    _finished = widget.controller.remaining <= Duration.zero;
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      _finished = widget.controller.remaining <= Duration.zero;
      widget.controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
    if (widget.controller.remaining > Duration.zero) {
      _finished = false;
      return;
    }
    if (!_finished) {
      _finished = true;
      widget.onFinished?.call();
    }
  }

  static String _format(Duration remaining) {
    final String minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final String seconds = (remaining.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );
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
