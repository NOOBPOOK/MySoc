import 'package:flutter/material.dart';

class CustomToast {
  /// Shows a custom toast overlay that slides down from the top and disappears after 5 seconds.
  ///
  /// [type] : -1 (Negative), 0 (Informational), 1 (Positive)
  /// [message] : The text content to display.
  static void show(BuildContext context,
      {required int type, required String message}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Determine colors and icons based on type
    Color bgColor;
    Color borderColor;
    IconData icon;
    Color iconColor;

    if (type == -1) {
      bgColor = const Color(0xFFFFEBEB); // Light Red
      borderColor = Colors.red;
      icon = Icons.error_outline;
      iconColor = Colors.red;
    } else if (type == 1) {
      bgColor = const Color(0xFFE8F5E9); // Light Green
      borderColor = Colors.green;
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
    } else {
      bgColor = const Color(0xFFF5F5F5); // Off white
      borderColor = Colors.grey;
      icon = Icons.info_outline;
      iconColor = Colors.grey;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        bgColor: bgColor,
        borderColor: borderColor,
        icon: icon,
        iconColor: iconColor,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Slide in from top
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: widget.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.iconColor),
                    const SizedBox(width: 12.0),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 14.0,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
