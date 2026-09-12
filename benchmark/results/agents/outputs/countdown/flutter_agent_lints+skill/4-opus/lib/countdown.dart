import 'dart:async';

import 'package:flutter/material.dart';

const _tick = Duration(seconds: 1);

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
    _timer = Timer.periodic(_tick, (_) => _onTick());
    notifyListeners();
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _stopTimer();
    notifyListeners();
  }

  void reset() {
    _stopTimer();
    _remaining = _duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _onTick() {
    final next = _remaining - _tick;
    if (next <= Duration.zero) {
      _remaining = Duration.zero;
      _stopTimer();
    } else {
      _remaining = next;
    }
    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

class CountdownTimer extends StatefulWidget {
  const new({required this.controller, this.onFinished, super.key});

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
    _listenTo(widget.controller);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onNotified);
      _listenTo(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNotified);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_formatted(widget.controller.remaining)),
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
  );

  void _listenTo(CountdownController controller) {
    _finished = controller.remaining == Duration.zero;
    controller.addListener(_onNotified);
  }

  void _onNotified() {
    if (!mounted) {
      return;
    }
    final reachedZero = widget.controller.remaining == Duration.zero;
    final finishedNow = reachedZero && !_finished;
    setState(() {
      _finished = reachedZero;
    });
    if (finishedNow) {
      widget.onFinished?.call();
    }
  }

  String _formatted(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
