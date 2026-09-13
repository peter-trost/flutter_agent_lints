import 'dart:async';

import 'package:flutter/material.dart';

/// Drives a countdown that ticks once a second and notifies on every tick.
///
/// The object that creates the controller owns it and is responsible for
/// disposing it; a widget handed one never does.
class CountdownController extends ChangeNotifier {
  new({required this._duration}) : _remaining = _duration;

  final Duration _duration;
  Duration _remaining;
  Timer? _timer;

  Duration get remaining => _remaining;

  bool get isRunning => _timer != null;

  /// Starts ticking. Does nothing while already running or at zero.
  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  /// Stops ticking and keeps the remaining time. Does nothing when stopped.
  void pause() {
    if (!isRunning) {
      return;
    }
    _stop();
    notifyListeners();
  }

  /// Stops ticking and restores the duration the controller was built with.
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

  void _tick(Timer timer) {
    const second = Duration(seconds: 1);
    _remaining = _remaining > second ? _remaining - second : Duration.zero;
    if (_remaining == Duration.zero) {
      _stop();
    }
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Shows the controller's remaining time as `mm:ss` with transport buttons.
class CountdownTimer extends StatefulWidget {
  const new({required this.controller, this.onFinished, super.key});

  final CountdownController controller;

  /// Called once each time the countdown reaches zero while mounted.
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late bool _finished;

  @override
  void initState() {
    super.initState();
    // A controller that is already at zero has finished before this widget
    // existed, so it must not fire the callback again.
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      _finished = widget.controller.remaining == Duration.zero;
      widget.controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_format(controller.remaining)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: controller.start, child: const Text('Start')),
            TextButton(onPressed: controller.pause, child: const Text('Pause')),
            TextButton(onPressed: controller.reset, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }

  void _handleChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final reachedZero = widget.controller.remaining == Duration.zero;
    if (!reachedZero) {
      // A reset (or a fresh controller) arms the callback again.
      _finished = false;
      return;
    }
    if (!_finished) {
      _finished = true;
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
