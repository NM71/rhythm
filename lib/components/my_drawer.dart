import 'package:flutter/material.dart';
import 'package:rhythm/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // logo
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  Image.asset(
                    'assets/rhythm-logo.png',
                    color: Theme.of(context).colorScheme.inversePrimary,
                    width: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.music_note, size: 50),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "R h y t h m",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
              // child: Icon(
              //   Icons.music_note,
              //   size: 50,
              //   color: Theme.of(context).colorScheme.inversePrimary,
              // ),
            ),
          ),

          // settings tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0, top: 25.0),
            child: ListTile(
              title: const Text("S E T T I N G S"),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),

          // about tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: ListTile(
              title: const Text("A B O U T"),
              leading: const Icon(Icons.info_outline),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: "Rhythm",
                  applicationVersion: "1.2.0",
                  applicationIcon: Image.asset(
                    'assets/rhythm-logo.png',
                    width: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.music_note, size: 50),
                  ),
                  children: [const Text("A premium music experience.")],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
