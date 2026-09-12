import 'dart:async';

import 'package:flutter/material.dart';

const _tick = Duration(seconds: 1);
const _bonus = Duration(seconds: 10);

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
    _timer = Timer.periodic(_tick, _onTick);
    notifyListeners();
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _cancel();
    notifyListeners();
  }

  void reset() {
    _cancel();
    _remaining = _duration;
    notifyListeners();
  }

  void addTime(Duration extra) {
    if (extra <= Duration.zero) {
      throw ArgumentError.value(extra, 'extra', 'must be greater than zero');
    }
    _remaining += extra;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    _remaining -= _tick;
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
}

class CountdownTimer extends StatefulWidget {
  const new({required this.controller, this.onFinished, super.key});

  final CountdownController controller;
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.controller.remaining;
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      _previous = widget.controller.remaining;
      widget.controller.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(_format(widget.controller.remaining)),
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
          TextButton(
            onPressed: () => widget.controller.addTime(_bonus),
            child: const Text('+10s'),
          ),
        ],
      ),
    ],
  );

  void _handleChange() {
    final remaining = widget.controller.remaining;
    final finished = remaining == Duration.zero && _previous > Duration.zero;
    _previous = remaining;
    if (mounted) {
      setState(() {});
    }
    if (finished) {
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
