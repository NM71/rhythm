import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/themes/theme_provider.dart';

class NeuBox extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapCancel;
  final VoidCallback? onLongPressEnd;

  const NeuBox({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onTapCancel,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    // is dark mode
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    Widget content = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // darker shadow on bottom right
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withAlpha((0.5 * 255).toInt())
                : Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(4, 4),
          ),

          //lighter shadow on top left
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withAlpha((0.05 * 255).toInt())
                : Colors.white,
            blurRadius: 15,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );

    if (onTap != null ||
        onLongPress != null ||
        onTapCancel != null ||
        onLongPressEnd != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onTapCancel: onTapCancel,
        onLongPressEnd: onLongPressEnd != null
            ? (_) => onLongPressEnd!()
            : null,
        child: content,
      );
    }

    return content;
  }
}
