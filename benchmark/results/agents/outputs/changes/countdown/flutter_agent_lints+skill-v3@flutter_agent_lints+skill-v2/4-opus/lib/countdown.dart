import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);
const _tenSeconds = Duration(seconds: 10);

class CountdownController extends ChangeNotifier {
  new({required this._duration});

  final Duration _duration;

  late Duration _remaining = _duration;
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

  void addTime(Duration extra) {
    if (extra <= Duration.zero) {
      throw ArgumentError.value(extra, 'extra', 'must be greater than zero');
    }
    _remaining += extra;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(Timer timer) {
    final next = _remaining - _oneSecond;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
      _cancelTimer();
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

  bool get _isFinished =>
      !widget.controller.isRunning &&
      widget.controller.remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    _finished = _isFinished;
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleChange);
    widget.controller.addListener(_handleChange);
    _finished = _isFinished;
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
        TextButton(onPressed: _addTenSeconds, child: const Text('+10s')),
      ],
    );
  }

  void _addTenSeconds() => widget.controller.addTime(_tenSeconds);

  void _handleChange() {
    if (!mounted) {
      return;
    }
    final isFinished = _isFinished;
    final justFinished = isFinished && !_finished;
    setState(() {
      _finished = isFinished;
    });
    if (justFinished) {
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
