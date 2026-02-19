import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/models/playlist_provider.dart';
import 'package:rhythm/models/song.dart';

class EditMetadataPage extends StatefulWidget {
  final Song song;

  const EditMetadataPage({super.key, required this.song});

  @override
  State<EditMetadataPage> createState() => _EditMetadataPageState();
}

class _EditMetadataPageState extends State<EditMetadataPage> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  bool _isLoading = false;
  Uint8List? _newArtworkBytes;
  String? _newArtworkMimeType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.songName);
    _artistController = TextEditingController(text: widget.song.artistName);
    _albumController = TextEditingController(text: widget.song.albumName);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickArtwork() async {
    try {
      // Check permissions before picking
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (!status.isGranted &&
            !await Permission.storage.request().isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gallery permission required to pick images.'),
              ),
            );
          }
          return;
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowCompression: true,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final extension = result.files.single.extension?.toLowerCase();

        setState(() {
          _newArtworkBytes = bytes;
          _newArtworkMimeType = (extension == 'png')
              ? 'image/png'
              : 'image/jpeg';
        });
      }
    } catch (e) {
      debugPrint("Error picking artwork: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting photo: $e')));
      }
    }
  }

  Future<void> _saveMetadata() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check permissions
      if (Platform.isAndroid) {
        if (!(await Permission.manageExternalStorage.request().isGranted ||
            await Permission.storage.request().isGranted)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission required.')),
            );
          }
          return;
        }
      }

      final path = widget.song.audioPath;
      Tag? tag;

      try {
        tag = await AudioTags.read(path);
      } catch (e) {
        debugPrint("Error reading existing tags: $e");
      }

      final newPictures = <Picture>[];
      if (_newArtworkBytes != null) {
        newPictures.add(
          Picture(
            bytes: _newArtworkBytes!,
            mimeType: _newArtworkMimeType == 'image/png'
                ? MimeType.png
                : MimeType.jpeg,
            pictureType: PictureType.coverFront,
          ),
        );
      } else if (tag?.pictures.isNotEmpty ?? false) {
        // Keep existing pictures if no new one is picked
        newPictures.addAll(tag!.pictures);
      }

      final newTag = Tag(
        title: _titleController.text.trim(),
        trackArtist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        year: tag?.year,
        genre: tag?.genre,
        trackNumber: tag?.trackNumber,
        discNumber: tag?.discNumber,
        pictures: newPictures,
      );

      await AudioTags.write(path, newTag);

      // FORCE MEDIA SCAN to update the system Store
      if (Platform.isAndroid) {
        await OnAudioQuery().scanMedia(path);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metadata updated successfully!')),
        );

        // Refresh provider to pick up changes
        Provider.of<PlaylistProvider>(context, listen: false).fetchSongs();

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Artwork Display
                  _buildArtworkDisplay(context),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          colorScheme.surface.withAlpha(50),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                  ),

                  // Change Artwork Button
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton.small(
                      heroTag: 'change_art',
                      onPressed: _pickArtwork,
                      child: const Icon(Icons.edit_rounded),
                    ),
                  ),
                ],
              ),
              title: Text(
                "Edit Info",
                style: TextStyle(
                  color: colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("SONG TITLE"),
                  _buildNeumorphicTextField(
                    _titleController,
                    Icons.music_note_rounded,
                  ),

                  const SizedBox(height: 24),

                  _buildInputLabel("ARTIST"),
                  _buildNeumorphicTextField(
                    _artistController,
                    Icons.person_rounded,
                  ),

                  const SizedBox(height: 24),

                  _buildInputLabel("ALBUM"),
                  _buildNeumorphicTextField(
                    _albumController,
                    Icons.album_rounded,
                  ),

                  const SizedBox(height: 48),

                  // Big Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation:
                            0, // Neumorphic style should be flat or custom shadows
                      ),
                      onPressed: _isLoading ? null : _saveMetadata,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isLoading ? "SAVING..." : "SAVE CHANGES",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      "File: ${widget.song.audioPath.split(Platform.pathSeparator).last}",
                      style: TextStyle(
                        color: colorScheme.inversePrimary.withAlpha(100),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 120), // Extra space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkDisplay(BuildContext context) {
    if (_newArtworkBytes != null) {
      return Image.memory(_newArtworkBytes!, fit: BoxFit.cover);
    }

    return QueryArtworkWidget(
      id: widget.song.id!,
      type: ArtworkType.AUDIO,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: Container(
        color: Theme.of(context).colorScheme.secondary.withAlpha(30),
        child: Icon(
          Icons.music_note_rounded,
          size: 100,
          color: Theme.of(context).colorScheme.primary.withAlpha(100),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary.withAlpha(180),
        ),
      ),
    );
  }

  Widget _buildNeumorphicTextField(
    TextEditingController controller,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white.withAlpha(10),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colorScheme.inversePrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: colorScheme.primary.withAlpha(150)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
