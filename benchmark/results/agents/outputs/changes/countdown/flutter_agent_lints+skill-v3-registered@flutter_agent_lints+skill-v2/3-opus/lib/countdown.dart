import 'dart:async';

import 'package:flutter/material.dart';

class CountdownController extends ChangeNotifier {
  new({required this._duration}) : _remaining = _duration;

  static const _tick = Duration(seconds: 1);

  final Duration _duration;
  Duration _remaining;
  Timer? _timer;

  Duration get remaining => _remaining;

  bool get isRunning => _timer != null;

  void start() {
    if (isRunning || _remaining <= Duration.zero) {
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

  void addTime(Duration extra) {
    if (extra <= Duration.zero) {
      throw ArgumentError.value(extra, 'extra', 'must be greater than zero');
    }
    _remaining += extra;
    notifyListeners();
  }

  void reset() {
    _cancel();
    _remaining = _duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTick(Timer timer) {
    final next = _remaining - _tick;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining <= Duration.zero) {
      _cancel();
    }
    notifyListeners();
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
  static const _bonus = Duration(seconds: 10);

  var _finished = false;

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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, child) => Column(
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
            TextButton(onPressed: _addBonus, child: const Text('+10s')),
          ],
        ),
      ],
    ),
  );

  String _formatted(Duration remaining) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _addBonus() => widget.controller.addTime(_bonus);

  void _handleChange() {
    if (widget.controller.remaining > Duration.zero) {
      _finished = false;
      return;
    }
    if (_finished) {
      return;
    }
    _finished = true;
    widget.onFinished?.call();
  }
}
