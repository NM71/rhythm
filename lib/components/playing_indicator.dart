import 'package:flutter/material.dart';

class PlayingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const PlayingIndicator({super.key, this.color, this.size = 20});

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int _barCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 150)),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: widget.size / (_barCount * 2),
                height: widget.size * _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.color ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
