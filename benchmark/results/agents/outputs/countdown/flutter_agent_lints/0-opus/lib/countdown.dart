import 'dart:async';

import 'package:flutter/material.dart';

const _tickInterval = Duration(seconds: 1);

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = (value.inSeconds % Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds';
}

class CountdownController extends ChangeNotifier {
  new({required Duration duration})
    : assert(!duration.isNegative, 'duration must not be negative'),
      _duration = duration,
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
    _timer = Timer.periodic(_tickInterval, _onTick);
    notifyListeners();
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _cancelTimer();
    notifyListeners();
  }

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

  void _onTick(Timer timer) {
    final next = _remaining - _tickInterval;
    if (next > Duration.zero) {
      _remaining = next;
    } else {
      _remaining = Duration.zero;
      _cancelTimer();
    }
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

class CountdownTimer extends StatefulWidget {
  const new({required this.controller, super.key, this.onFinished});

  final CountdownController controller;
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining = widget.controller.remaining;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _remaining = widget.controller.remaining;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_formatDuration(_remaining)),
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

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    final remaining = widget.controller.remaining;
    final finished = remaining == Duration.zero && _remaining > Duration.zero;
    setState(() {
      _remaining = remaining;
    });
    if (finished) {
      widget.onFinished?.call();
    }
  }
}
