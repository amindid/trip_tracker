import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/travel_log.dart';
import '../services/storage_service.dart';
import '../widgets/photo_group_card.dart';
import 'photo_detail_screen.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => PhotosScreenState();
}


class PhotosScreenState extends State<PhotosScreen> {
  List<TravelLog> _logsWithPhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  // Method to refresh photos from external calls
  void refreshPhotos() {
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allLogs = await StorageService.loadTravelLogs();
      final logsWithPhotos = allLogs.where((log) => log.hasPhotos).toList();
      
      // Sort by timestamp (newest first)
      logsWithPhotos.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _logsWithPhotos = logsWithPhotos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photos: $e')),
        );
      }
    }
  }

  void _openPhotoDetail(TravelLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(log: log),
      ),
    ).then((result) {
      if (result == true) {
        _loadPhotos(); // Refresh if any log was modified
      }
    });
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No photos yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to your travel logs to see them here!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Adjusted for better photo group cards
      ),
      itemCount: _logsWithPhotos.length,
      itemBuilder: (context, index) {
        final log = _logsWithPhotos[index];
        return PhotoGroupCard(
          log: log,
          onTap: () => _openPhotoDetail(log),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Groups (${_logsWithPhotos.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logsWithPhotos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPhotos,
                  child: _buildPhotoGrid(),
                ),
    );
  }
}

