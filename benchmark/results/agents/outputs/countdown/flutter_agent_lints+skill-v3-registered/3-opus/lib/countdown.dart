import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

class CountdownController extends ChangeNotifier {
  new({required this._duration});

  final Duration _duration;

  Timer? _timer;
  late Duration _remaining = _duration;

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

  void _tick() {
    _remaining -= _oneSecond;
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
  var _wasFinished = false;

  @override
  void initState() {
    super.initState();
    _wasFinished = _isFinished(widget.controller);
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleChange);
    _wasFinished = _isFinished(widget.controller);
    widget.controller.addListener(_handleChange);
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

  bool _isFinished(CountdownController controller) =>
      controller.remaining == Duration.zero;

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleChange() {
    final finished = _isFinished(widget.controller);
    final justFinished = finished && !_wasFinished;
    setState(() {
      _wasFinished = finished;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }
}
