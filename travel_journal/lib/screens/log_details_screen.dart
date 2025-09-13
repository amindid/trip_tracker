import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/travel_log.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';

class LogDetailsScreen extends StatefulWidget {
  final TravelLog log;

  const LogDetailsScreen({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailsScreen> createState() => _LogDetailsScreenState();
}

class _LogDetailsScreenState extends State<LogDetailsScreen> {
  late TravelLog _log;
  final _noteController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _noteController.text = _log.note ?? '';
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedLog = _log.copyWith(
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      await StorageService.updateTravelLog(updatedLog);
      
      setState(() {
        _log = updatedLog;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Travel log updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating log: $e')),
        );
      }
    }
  }

  Future<void> _deleteLog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Travel Log'),
        content: const Text('Are you sure you want to delete this travel log? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StorageService.deleteTravelLog(_log.id);
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate deletion
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Travel log deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting log: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareLog() async {
    final buffer = StringBuffer();
    buffer.writeln('Travel Log');
    buffer.writeln('=' * 20);
    
    if (_log.locationName != null) {
      buffer.writeln('Location: ${_log.locationName}');
    }
    buffer.writeln('Coordinates: ${LocationService.formatCoordinates(_log.latitude, _log.longitude)}');
    buffer.writeln('Date: ${DateFormat('MMM d, yyyy HH:mm').format(_log.timestamp)}');
    
    if (_log.note != null && _log.note!.isNotEmpty) {
      buffer.writeln('\nNote: ${_log.note}');
    }
    
    buffer.writeln('\nShared from Travel Journal');

    await Share.share(
      buffer.toString(),
      subject: 'Travel Log - ${_log.locationName ?? 'Location'}',
    );
  }

  void _copyCoordinates() {
    final coordinates = LocationService.formatCoordinates(_log.latitude, _log.longitude);
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied to clipboard')),
    );
  }

  Widget _buildPhotosSection() {
    final allPhotos = _log.allPhotoPaths;
    if (allPhotos.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  allPhotos.length == 1 ? 'Photo' : 'Photos (${allPhotos.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (allPhotos.length == 1) ...[
            GestureDetector(
              onTap: () => _showFullScreenPhoto(0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPhotoWidget(allPhotos.first, BoxFit.cover),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allPhotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _showFullScreenPhoto(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 150,
                          child: _buildPhotoWidget(allPhotos[index], BoxFit.cover),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(String photoPath, BoxFit fit) {
    return kIsWeb
      ? FutureBuilder<String?>(
          future: StorageService.getWebPhotoData(photoPath),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.network(
                snapshot.data!,
                fit: fit,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 48,
                    ),
                  );
                },
              );
            } else {
              return Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.broken_image,
                  color: Colors.grey[600],
                  size: 48,
                ),
              );
            }
          },
        )
      : Image.file(
          File(photoPath),
          fit: fit,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[600],
                size: 48,
              ),
            );
          },
        );
  }

  void _showFullScreenPhoto(int initialIndex) {
    final allPhotos = _log.allPhotoPaths;
    if (allPhotos.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photoPaths: allPhotos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_log.locationName != null) ...[
              Text(
                _log.locationName!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    LocationService.formatCoordinates(_log.latitude, _log.longitude),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyCoordinates,
                  tooltip: 'Copy coordinates',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date & Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_log.timestamp),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(_log.timestamp),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                        _noteController.text = _log.note ?? '';
                      });
                    },
                    tooltip: 'Edit note',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              TextField(
                controller: _noteController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Add your notes about this location...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _noteController.text = _log.note ?? '';
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ] else ...[
              if (_log.note != null && _log.note!.isNotEmpty) ...[
                Text(
                  _log.note!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ] else ...[
                Text(
                  'No notes added',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_log.locationName ?? 'Travel Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLog,
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _deleteLog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotosSection(),
            const SizedBox(height: 16),
            _buildLocationInfo(),
            const SizedBox(height: 16),
            _buildDateTimeInfo(),
            const SizedBox(height: 16),
            _buildNotesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}

class _PhotoViewerScreen extends StatefulWidget {
  final List<String> photoPaths;
  final int initialIndex;

  const _PhotoViewerScreen({
    required this.photoPaths,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  Widget _buildPhotoWidget(String photoPath) {
    return kIsWeb
      ? FutureBuilder<String?>( 
          future: StorageService.getWebPhotoData(photoPath),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.network(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              );
            } else {
              return Container(
                color: Colors.grey[800],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              );
            }
          },
        )
      : Image.file(
          File(photoPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[800],
              child: const Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 64,
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} of ${widget.photoPaths.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.photoPaths.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: _buildPhotoWidget(widget.photoPaths[index]),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}