import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

String _formatRemaining(Duration remaining) {
  final minutes = remaining.inMinutes.toString().padLeft(2, '0');
  final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
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
    _timer = Timer.periodic(_oneSecond, (_) => _tick());
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

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    final next = _remaining - _oneSecond;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
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
      oldWidget.controller.removeListener(_handleChange);
      _listenTo(widget.controller);
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
        Text(_formatRemaining(controller.remaining)),
        TextButton(onPressed: controller.start, child: const Text('Start')),
        TextButton(onPressed: controller.pause, child: const Text('Pause')),
        TextButton(onPressed: controller.reset, child: const Text('Reset')),
      ],
    );
  }

  void _listenTo(CountdownController controller) {
    _finished = controller.remaining == Duration.zero;
    controller.addListener(_handleChange);
  }

  void _handleChange() {
    if (!mounted) {
      return;
    }
    final done = widget.controller.remaining == Duration.zero;
    final justFinished = done && !_finished;
    setState(() {
      _finished = done;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }
}
