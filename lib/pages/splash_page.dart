import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rhythm/pages/main_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate to HomePage after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/rhythm-logo-1.png', width: 150, height: 150),
              // const SizedBox(height: 20),
              // // Title
              // Text(
              //   "R H Y T H M",
              //   style: TextStyle(
              //     fontSize: 25,
              //     fontWeight: FontWeight.bold,
              //     letterSpacing: 4,
              //     color: Theme.of(context).colorScheme.inversePrimary,
              //   ),
              // ),
              // const SizedBox(height: 10),
              // Tagline
              // Text(
              //   "Music is what feelings sound like",
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Theme.of(context).colorScheme.primary,
              //     fontStyle: FontStyle.italic,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
