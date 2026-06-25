import 'dart:async';

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static OverlayEntry? _currentEntry;

  static void showError(String message, {Duration duration = const Duration(seconds: 3)}) {
    _show(message, duration: duration, backgroundColor: Colors.black87);
  }

  static void showMessage(String message, {Duration duration = const Duration(seconds: 2)}) {
    _show(message, duration: duration, backgroundColor: Colors.green);
  }

  static void _show(String message, {required Duration duration, required Color backgroundColor}) {
    final nav = notificationNavigatorKey.currentState;
    if (nav == null) return;

    // remove existing
    _removeCurrent();

    final overlay = nav.overlay;
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) {
        return _PopupOverlay(
          message: message,
          backgroundColor: backgroundColor,
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Timer(duration, () {
      _removeCurrent();
    });
  }

  static void _removeCurrent() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _PopupOverlay extends StatefulWidget {
  final String message;
  final Color backgroundColor;

  const _PopupOverlay({required this.message, required this.backgroundColor});

  @override
  State<_PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<_PopupOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _animation,
              child: GestureDetector(
                onTap: () {
                  // dismiss on tap
                  NotificationService._removeCurrent();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
