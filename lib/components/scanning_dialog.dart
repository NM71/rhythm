import 'package:flutter/material.dart';
import 'package:rhythm/models/playlist_provider.dart';

class ScanningDialog extends StatelessWidget {
  final PlaylistProvider provider;

  const ScanningDialog({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scanning Audio Files'),
      content: SizedBox(
        height: 100,
        child: Column(
          children: [
            const Text('Please wait while we scan your audio files...'),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: provider.scanProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 10),
            Text('${(provider.scanProgress * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            provider.cancelScan();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}