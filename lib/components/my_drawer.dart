import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rhythm/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Logo
          DrawerHeader(
            child:
            SvgPicture.asset(
              'assets/images/music_rhythm_icon.svg',
              height: 40,
              width: 40,
            ),
          ),

          // Home tile
          Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 30.0),
            child: ListTile(
              title: const Text(' H O M E'),
              leading: const Icon(Icons.home),
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Settings
          Padding(
            padding: const EdgeInsets.only(left: 30.0, top: 0.0),
            child: ListTile(
              title: const Text(' S E T T I N G S'),
              leading: const Icon(Icons.settings),
              onTap: () {
                // first pop
                Navigator.pop(context);
                // then navigate to settings page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => const SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
