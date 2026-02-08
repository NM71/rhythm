import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';

class LibraryScanningPage extends StatefulWidget {
  const LibraryScanningPage({super.key});

  @override
  State<LibraryScanningPage> createState() => _LibraryScanningPageState();
}

class _LibraryScanningPageState extends State<LibraryScanningPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isScanning = false;
  double _progress = 0.0;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(PlaylistProvider provider) async {
    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _resultMessage = null;
    });
    _animationController.repeat(reverse: true);

    // Simulate progress while scanning
    // Every scan should take at least 1-2 seconds for visual feedback
    const steps = 100;
    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      await Future.delayed(
        Duration(milliseconds: i < 30 ? 30 : (i < 80 ? 10 : 20)),
      );
      setState(() {
        _progress = i / steps;
      });

      // At certain points, we can do the actual scan logic
      if (i == 50) {
        // Kick off actual scan in background or wait for it
      }
    }

    // Perform actual scan (already fast, so we do it at the end)
    int newSongs = await provider.scanSongs();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _progress = 1.0;
        _resultMessage = newSongs > 0
            ? "$newSongs new songs added to your library!"
            : "Your library is already up to date.";
      });
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text("L I B R A R Y"),
        centerTitle: true,
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            children: [
              // Animated Scan Button Section
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: GestureDetector(
                        onTap: _isScanning ? null : () => _handleScan(provider),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha((0.1 * 255).toInt()),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary
                                  .withAlpha((0.2 * 255).toInt()),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withAlpha((0.3 * 255).toInt()),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_isScanning)
                                    SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: CircularProgressIndicator(
                                        value: _progress,
                                        color: Colors.white,
                                        backgroundColor: Colors.white24,
                                        strokeWidth: 6,
                                      ),
                                    ),
                                  if (_isScanning)
                                    Text(
                                      "${(_progress * 100).toInt()}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _isScanning ? "Scanning Storage..." : "Scan Library",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _resultMessage ?? "Tap to search for music",
                        key: ValueKey(_resultMessage),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.inversePrimary
                              .withAlpha((0.6 * 255).toInt()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Filter Section
              Text(
                "SCAN FILTERS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildFilterTile(
                      context,
                      title: "Filter by Duration",
                      subtitle: "Skip recording & notifications",
                      trailing: DropdownButton<int>(
                        value: provider.minSongDurationMs,
                        underline: const SizedBox(),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onChanged: (value) {
                          if (value != null) provider.setMinSongDuration(value);
                        },
                        items: const [
                          DropdownMenuItem(value: 0, child: Text("Show All")),
                          DropdownMenuItem(value: 15000, child: Text("> 15s")),
                          DropdownMenuItem(value: 30000, child: Text("> 30s")),
                          DropdownMenuItem(value: 60000, child: Text("> 1min")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Bottom Info
              Opacity(
                opacity: 0.5,
                child: Column(
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 20),
                    SizedBox(height: 12),
                    Text(
                      "Rhythm scans your device storage for audio files. Only files meeting your filters will be added to your library.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.inversePrimary.withAlpha((0.5 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
