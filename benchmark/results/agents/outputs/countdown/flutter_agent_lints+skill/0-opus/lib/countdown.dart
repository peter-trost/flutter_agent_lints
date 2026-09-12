import 'dart:async';

import 'package:flutter/material.dart';

const _oneSecond = Duration(seconds: 1);

class CountdownController extends ChangeNotifier {
  new({required this._duration}) : _remaining = _duration;

  final Duration _duration;

  Duration _remaining;
  Timer? _ticker;

  Duration get remaining => _remaining;

  bool get isRunning => _ticker != null;

  void start() {
    if (isRunning || _remaining == Duration.zero) {
      return;
    }
    _ticker = Timer.periodic(_oneSecond, (_) => _tick());
  }

  void pause() {
    if (!isRunning) {
      return;
    }
    _stopTicker();
  }

  void reset() {
    _stopTicker();
    _remaining = _duration;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _tick() {
    final next = _remaining - _oneSecond;
    _remaining = next > Duration.zero ? next : Duration.zero;
    if (_remaining == Duration.zero) {
      _stopTicker();
    }
    notifyListeners();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
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
  late var _wasFinished = widget.controller.remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _wasFinished = widget.controller.remaining == Duration.zero;
    }
  }

  @override
  void dispose() {
    // The caller owns the controller, so only the listener is released here.
    widget.controller.removeListener(_onControllerChanged);
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
        ],
      ),
    ],
  );

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    final finished = widget.controller.remaining == Duration.zero;
    final justFinished = finished && !_wasFinished;
    setState(() {
      _wasFinished = finished;
    });
    if (justFinished) {
      widget.onFinished?.call();
    }
  }

  String _format(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:'
      '${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}
