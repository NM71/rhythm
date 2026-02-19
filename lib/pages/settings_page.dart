import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/pages/about_page.dart';
import 'package:rhythm/themes/theme_provider.dart';
import 'package:rhythm/models/playlist_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("S E T T I N G S"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Dark Mode Toggle
          _buildSettingsTile(
            context,
            title: "Dark Mode",
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Clear Favorites
          _buildSettingsTile(
            context,
            title: "Clear Favorites",
            subtitle: "Remove all favorited songs",
            trailing: Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                return TextButton(
                  onPressed: provider.favoriteIds.isEmpty
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Clear Favorites?"),
                              content: const Text(
                                "This will remove all songs from your favorites list.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.clearFavorites();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Favorites cleared"),
                                      ),
                                    );
                                  },
                                  child: const Text("Clear"),
                                ),
                              ],
                            ),
                          );
                        },
                  child: Text("Clear (${provider.favoriteIds.length})"),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // // Library Scanning Section
          // const Text(
          //   "Library Scanning",
          //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: 16),
          // _buildSettingsTile(
          //   context,
          //   title: "Manual Scan",
          //   subtitle: "Force a refresh of your music library",
          //   trailing: Consumer<PlaylistProvider>(
          //     builder: (context, provider, child) {
          //       return IconButton(
          //         icon: const Icon(Icons.refresh),
          //         onPressed: () {
          //           provider.scanSongs();
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text("Library scanned")),
          //           );
          //         },
          //       );
          //     },
          //   ),
          // ),
          // const SizedBox(height: 16),
          // _buildSettingsTile(
          //   context,
          //   title: "Filter by Duration",
          //   subtitle: "Hide short audio files (like notifications)",
          //   trailing: Consumer<PlaylistProvider>(
          //     builder: (context, provider, child) {
          //       return DropdownButton<int>(
          //         value: provider.minSongDurationMs,
          //         underline: const SizedBox(),
          //         onChanged: (value) {
          //           if (value != null) provider.setMinSongDuration(value);
          //         },
          //         items: const [
          //           DropdownMenuItem(value: 0, child: Text("Show All")),
          //           DropdownMenuItem(value: 15000, child: Text("> 15s")),
          //           DropdownMenuItem(value: 30000, child: Text("> 30s")),
          //           DropdownMenuItem(value: 60000, child: Text("> 1min")),
          //         ],
          //       );
          //     },
          //   ),
          // ),
          const SizedBox(height: 32),

          // Playback History Section
          const Text(
            "Playback History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            title: "Clear Recently Played",
            subtitle: "Wipe your playback history",
            trailing: Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                return TextButton(
                  onPressed: provider.recentlyPlayed.isEmpty
                      ? null
                      : () {
                          provider.clearRecentlyPlayed();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("History cleared")),
                          );
                        },
                  child: const Text("Clear"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
              ],
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
