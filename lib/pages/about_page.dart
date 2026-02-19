import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Text("A B O U T"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/rhythm-logo-new.png',
                  color: colorScheme.inversePrimary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App Name
            Text(
              'Rhythm',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.inversePrimary,
              ),
            ),

            const SizedBox(height: 4),

            // Version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.inversePrimary.withAlpha(120),
              ),
            ),

            const SizedBox(height: 24),

            // Description Card
            _buildCard(
              context,
              child: Column(
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'An offline music player built with ❤️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.inversePrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enjoy local music collection with a clean, '
                    'interface. No ads, no tracking, no internet required.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.inversePrimary.withAlpha(150),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Features Card
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    context,
                    Icons.queue_music_rounded,
                    'Queue & playlist management',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.favorite_rounded,
                    'Favorites & custom playlists',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.search_rounded,
                    'Smart search',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.sort_rounded,
                    'Multiple sorting options',
                  ),
                  _buildFeatureRow(
                    context,
                    Icons.dark_mode_rounded,
                    'Dark & light theme',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Developer Card
            _buildCard(
              context,
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.inversePrimary.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nousher Murtaza',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built with Flutter',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.inversePrimary.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Text(
              '© 2026 Rhythm. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.inversePrimary.withAlpha(80),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.inversePrimary.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
