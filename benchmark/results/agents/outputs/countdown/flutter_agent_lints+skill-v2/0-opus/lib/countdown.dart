import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

class CountdownController extends ChangeNotifier {
  new({required this._duration}) : _remaining = _duration;

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
    notifyListeners();
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

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(Timer timer) {
    final next = _remaining - _oneSecond;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
      _stop();
    }
    notifyListeners();
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
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_handleUpdate);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleUpdate);
      widget.controller.addListener(_handleUpdate);
      _finished = widget.controller.remaining == Duration.zero;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_formatted(widget.controller.remaining)),
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

  String _formatted(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleUpdate() {
    final hasFinished = widget.controller.remaining == Duration.zero;
    final justFinished = hasFinished && !_finished;
    setState(() {
      _finished = hasFinished;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }
}
