import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/travel_log.dart';
import '../services/storage_service.dart';

class PhotoGroupCard extends StatelessWidget {
  final TravelLog log;
  final VoidCallback onTap;

  const PhotoGroupCard({
    super.key,
    required this.log,
    required this.onTap,
  });

  Widget _buildPhotoWidget() {
    final primaryPhoto = log.primaryPhotoPath;
    if (primaryPhoto == null) {
      return Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.photo_camera_outlined,
          color: Colors.grey[600],
          size: 32,
        ),
      );
    }

    return kIsWeb
      ? FutureBuilder<String?>(
          future: StorageService.getWebPhotoData(primaryPhoto),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.network(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[600],
                      size: 32,
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
                  size: 32,
                ),
              );
            }
          },
        )
      : Image.file(
          File(primaryPhoto),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[600],
                size: 32,
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final allPhotos = log.allPhotoPaths;
    
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo preview with count indicator
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhotoWidget(),
                  
                  // Multiple photos indicator
                  if (allPhotos.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${allPhotos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Photo details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title/Location
                    Text(
                      log.locationName ?? 'Travel Memory',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy').format(log.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Note preview (if exists)
                    if (log.note != null && log.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          log.note!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}