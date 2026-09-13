import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

/// Counts down from the given duration to zero, one second at a time.
class CountdownController extends ChangeNotifier {
  new({required Duration duration})
    : _duration = duration,
      _remaining = duration;

  final Duration _duration;

  Duration _remaining;
  Timer? _timer;

  Duration get remaining => _remaining;

  bool get isRunning => _timer != null;

  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_oneSecond, _tick);
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _stop();
  }

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
    _remaining -= _oneSecond;
    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _stop();
    }
    notifyListeners();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Shows the [controller]'s remaining time and drives it from three buttons.
class CountdownTimer extends StatefulWidget {
  const new({required this.controller, super.key, this.onFinished});

  final CountdownController controller;
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
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
      _finished = widget.controller.remaining == Duration.zero;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
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

  void _handleControllerChange() {
    final finished = widget.controller.remaining == Duration.zero;
    setState(() {});
    if (finished && !_finished) {
      widget.onFinished?.call();
    }
    _finished = finished;
  }

  String _format(Duration remaining) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
