import 'dart:async';

import 'package:flutter/material.dart';

class CountdownController extends ChangeNotifier {
  CountdownController({required Duration duration})
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _remaining = _duration;
    notifyListeners();
  }

  void _tick() {
    _remaining -= const Duration(seconds: 1);
    if (_remaining <= Duration.zero) {
      _remaining = Duration.zero;
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.controller, this.onFinished});

  final CountdownController controller;
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  bool _wasRunning = false;

  @override
  void initState() {
    super.initState();
    _wasRunning = widget.controller.isRunning;
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _wasRunning = widget.controller.isRunning;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final controller = widget.controller;
    final finished =
        _wasRunning &&
        !controller.isRunning &&
        controller.remaining == Duration.zero;
    _wasRunning = controller.isRunning;
    if (finished) {
      widget.onFinished?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.controller.remaining;
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$minutes:$seconds'),
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
  }
}
