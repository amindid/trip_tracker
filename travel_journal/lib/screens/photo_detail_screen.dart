import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/travel_log.dart';
import '../services/storage_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final TravelLog log;
  final int initialPhotoIndex;

  const PhotoDetailScreen({
    super.key,
    required this.log,
    this.initialPhotoIndex = 0,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int _currentPhotoIndex;
  late TravelLog _log;

  @override
  void initState() {
    super.initState();
    _log = widget.log;
    _currentPhotoIndex = widget.initialPhotoIndex;
    _pageController = PageController(initialPage: widget.initialPhotoIndex);
  }



  Widget _buildPhotoWidget(String photoPath) {
    return kIsWeb
      ? FutureBuilder<String?>(
          future: StorageService.getWebPhotoData(photoPath),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return InteractiveViewer(
                child: Image.network(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    );
                  },
                ),
              );
            } else {
              return Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              );
            }
          },
        )
      : InteractiveViewer(
          child: Image.file(
            File(photoPath),
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              );
            },
          ),
        );
  }


  @override
  Widget build(BuildContext context) {
    final allPhotos = _log.allPhotoPaths;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _log.locationName ?? 'Travel Photo',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: allPhotos.length == 1
        ? _buildPhotoWidget(allPhotos.first)
        : PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemCount: allPhotos.length,
            itemBuilder: (context, index) {
              return _buildPhotoWidget(allPhotos[index]);
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