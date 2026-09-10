import 'dart:async';

import 'package:flutter/material.dart';

const _tick = Duration(seconds: 1);

String _format(Duration value) {
  final minutes = value.inMinutes.toString().padLeft(2, '0');
  final seconds = (value.inSeconds % Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
  return '$minutes:$seconds';
}

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
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _cancel();
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

  void _onTick(Timer timer) {
    final next = _remaining - _tick;
    if (next <= Duration.zero) {
      _remaining = Duration.zero;
      _cancel();
    } else {
      _remaining = next;
    }
    notifyListeners();
  }

  void _cancel() {
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
  var _finished = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
      _finished = false;
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
        TextButton(onPressed: controller.start, child: const Text('Start')),
        TextButton(onPressed: controller.pause, child: const Text('Pause')),
        TextButton(onPressed: controller.reset, child: const Text('Reset')),
      ],
    );
  }

  void _handleChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (widget.controller.remaining == Duration.zero) {
      if (!_finished) {
        _finished = true;
        widget.onFinished?.call();
      }
    } else {
      _finished = false;
    }
  }
}
