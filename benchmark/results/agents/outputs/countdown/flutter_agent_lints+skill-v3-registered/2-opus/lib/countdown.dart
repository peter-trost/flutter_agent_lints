import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

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

  void _tick(Timer timer) {
    final next = _remaining - _oneSecond;
    if (next <= Duration.zero) {
      _remaining = Duration.zero;
      _cancelTimer();
    } else {
      _remaining = next;
    }
    notifyListeners();
  }

  void _cancelTimer() {
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
  late bool _wasFinished = _isFinished;

  bool get _isFinished => widget.controller.remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _wasFinished = _isFinished;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_formatDuration(widget.controller.remaining)),
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

  void _handleControllerChanged() {
    final isFinished = _isFinished;
    final justFinished = isFinished && !_wasFinished;
    setState(() {
      _wasFinished = isFinished;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }
}
