import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/themes/theme_provider.dart';

class NeuBox extends StatelessWidget {
  final Widget? child;

  const NeuBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // is dark mode
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
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
      padding: EdgeInsets.all(12),
      child: child,
    );
  }
}
