import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration scrollDuration;
  final Duration pauseDuration;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.scrollDuration = const Duration(seconds: 10),
    this.pauseDuration = const Duration(seconds: 2),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll() async {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent <= 0) return;

    await Future.delayed(widget.pauseDuration);

    while (_scrollController.hasClients) {
      await _scrollController.animateTo(
        maxScrollExtent,
        duration: widget.scrollDuration,
        curve: Curves.linear,
      );

      await Future.delayed(widget.pauseDuration);

      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(widget.pauseDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
