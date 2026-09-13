import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

class CountdownController extends ChangeNotifier {
  new({required this._duration});

  final Duration _duration;

  Timer? _timer;
  late var _remaining = _duration;

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
    _cancel();
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

  void _tick(Timer timer) {
    if (_remaining <= _oneSecond) {
      _remaining = Duration.zero;
      _cancel();
    } else {
      _remaining -= _oneSecond;
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
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _finished = widget.controller.remaining == Duration.zero;
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChange);
      _finished = widget.controller.remaining == Duration.zero;
      widget.controller.addListener(_handleChange);
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: controller.start, child: const Text('Start')),
            TextButton(onPressed: controller.pause, child: const Text('Pause')),
            TextButton(onPressed: controller.reset, child: const Text('Reset')),
          ],
        ),
      ],
    );
  }

  void _handleChange() {
    final finished = widget.controller.remaining == Duration.zero;
    final justFinished = finished && !_finished;
    setState(() {
      _finished = finished;
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
