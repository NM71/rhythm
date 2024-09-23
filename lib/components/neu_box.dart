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
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          // darker shadow on bottom right
          BoxShadow(
            color: isDarkMode ? Colors.black: Colors.grey.shade500,
            blurRadius: 15,
            offset: const Offset(4, 4),
          ),
          // lighter shadow on top left
          BoxShadow(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
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
