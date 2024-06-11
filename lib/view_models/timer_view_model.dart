import 'dart:async';

import 'package:flutter/foundation.dart';

class TimerViewModel extends ChangeNotifier {
  DateTime now;

  final _second = const Duration(seconds: 1);

  TimerViewModel() : now = DateTime.now() {
    _start();
  }

  Timer _start() => Timer.periodic(_second, (timer) {
        now = now.add(_second);
        notifyListeners();
      });
}
