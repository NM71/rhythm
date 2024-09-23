import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/pages/home_page.dart';
import 'package:rhythm/pages/song_page.dart';
import 'package:rhythm/themes/theme_provider.dart';

// void main() {
//   // runApp(const MyApp());
//   runApp(
//     ChangeNotifierProvider(create: (context) => ThemeProvider(),
//     child: const MyApp(),)
//   );
// }

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => PlaylistProvider()),
      ],
      // child: DevicePreview(
      //   builder: (context) => const MyApp(),
      // ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
