import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] with the current time every [interval], and when the
/// app returns to the foreground.
class Clock extends StatefulWidget {
  const Clock({super.key, required this.interval, required this.builder});

  final Duration interval;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> with WidgetsBindingObserver {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _tick());
  }

  void _tick() {
    if (mounted) setState(() => _now = DateTime.now());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      _start();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
