import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:rhythm/models/playlist_provider.dart';

class FolderSelectionPage extends StatefulWidget {
  const FolderSelectionPage({super.key});

  @override
  State<FolderSelectionPage> createState() => _FolderSelectionPageState();
}

class _FolderSelectionPageState extends State<FolderSelectionPage> {
  String _currentPath = '/storage/emulated/0';
  Map<String, String> _volumes = {};
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;
  List<String> _selectedFolders = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    _selectedFolders = List.from(provider.selectedFolders);
    _initStorage();
  }

  Future<void> _initStorage() async {
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    _volumes = await provider.getStorageVolumes();

    // Set initial path to the first volume if current doesn't exist
    if (!_volumes.values.contains(_currentPath) && _volumes.isNotEmpty) {
      _currentPath = _volumes.values.first;
    }

    await _loadDirectory(_currentPath);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() => _isLoading = true);
    final provider = Provider.of<PlaylistProvider>(context, listen: false);
    final entities = await provider.listDirectory(path);

    // Sort: Folders first, then files
    entities.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _currentPath = path;
        _entities = entities;
        _isLoading = false;
      });
    }
  }

  void _onBack() {
    if (_volumes.values.contains(_currentPath)) {
      Navigator.pop(context);
    } else {
      final parent = Directory(_currentPath).parent.path;
      _loadDirectory(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _volumes.values.contains(_currentPath),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBack,
          ),
          title: Text(
            _volumes.entries
                .firstWhere(
                  (e) => _currentPath.startsWith(e.value),
                  orElse: () => MapEntry("Storage", ""),
                )
                .key,
          ),
          actions: [
            // Storage Switcher
            if (_volumes.length > 1)
              PopupMenuButton<String>(
                icon: const Icon(Icons.storage_rounded),
                onSelected: _loadDirectory,
                itemBuilder: (context) => _volumes.entries
                    .map(
                      (e) => PopupMenuItem(
                        value: e.value,
                        child: Row(
                          children: [
                            Icon(
                              e.key.contains("SD")
                                  ? Icons.sd_storage
                                  : Icons.phone_android,
                            ),
                            const SizedBox(width: 10),
                            Text(e.key),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        body: Column(
          children: [
            // Breadcrumbs or Path Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.secondary.withAlpha(50),
              child: Text(
                _currentPath,
                style: const TextStyle(
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _entities.length,
                      itemBuilder: (context, index) {
                        final entity = _entities[index];
                        final isDirectory = entity is Directory;
                        final name = entity.path
                            .split(Platform.pathSeparator)
                            .last;
                        final isSelected = _selectedFolders.any(
                          (p) => entity.path.startsWith(p),
                        );
                        final isPartiallySelected =
                            isSelected ||
                            _selectedFolders.any(
                              (p) => p.startsWith(entity.path),
                            );

                        return ListTile(
                          leading: Icon(
                            isDirectory
                                ? Icons.folder
                                : Icons.audio_file_outlined,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : isPartiallySelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(150)
                                : null,
                          ),
                          title: Text(name),
                          trailing: isDirectory
                              ? Checkbox(
                                  value: _selectedFolders.contains(entity.path),
                                  tristate:
                                      !_selectedFolders.contains(entity.path) &&
                                      isPartiallySelected,
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        // Add this folder, remove any nested selected folders since this covers them
                                        _selectedFolders.removeWhere(
                                          (p) => p.startsWith(entity.path),
                                        );
                                        _selectedFolders.add(entity.path);
                                      } else {
                                        _selectedFolders.remove(entity.path);
                                      }
                                    });
                                  },
                                )
                              : null,
                          onTap: isDirectory
                              ? () => _loadDirectory(entity.path)
                              : null,
                        );
                      },
                    ),
            ),

            // Selection Summary and Apply
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "${_selectedFolders.length} directories selected",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_selectedFolders.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedFolders = []),
                          child: const Text("Clear"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final provider = Provider.of<PlaylistProvider>(
                          context,
                          listen: false,
                        );
                        provider.setSelectedFolders(_selectedFolders);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Apply Selection",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
