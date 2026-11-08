import 'package:flutter/material.dart';

class AmbientMode extends ChangeNotifier {
  Color _dominantColor = const Color(0xFFE50914);
  bool _enabled = false;

  Color get dominantColor => _dominantColor;
  bool get enabled => _enabled;

  void setColor(Color color) {
    if (!_enabled) return;
    _dominantColor = color;
    notifyListeners();
  }

  void toggle() {
    _enabled = !_enabled;
    notifyListeners();
  }

  void enable() {
    _enabled = true;
    notifyListeners();
  }

  void disable() {
    _enabled = false;
    notifyListeners();
  }

  BoxDecoration tintedDecoration({
    required Color fallback,
    double opacity = 0.05,
    double blurRadius = 40,
  }) {
    return BoxDecoration(
      color: _enabled ? fallback : fallback,
      boxShadow: _enabled
          ? [
              BoxShadow(
                color: _dominantColor.withAlpha((opacity * 255).toInt()),
                blurRadius: blurRadius,
                spreadRadius: 5,
              ),
            ]
          : null,
    );
  }
}

final ambientMode = AmbientMode();
