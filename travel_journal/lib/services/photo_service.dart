import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  /// Check and request camera permissions
  static Future<bool> requestCameraPermission() async {
    // On web, permissions are handled by the browser
    if (kIsWeb) {
      return true;
    }
    
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  /// Check and request photos permissions
  static Future<bool> requestPhotosPermission() async {
    // On web, permissions are handled by the browser
    if (kIsWeb) {
      return true;
    }
    
    final status = await Permission.photos.request();
    return status == PermissionStatus.granted || 
           status == PermissionStatus.limited;
  }

  /// Take photo using camera
  static Future<File?> takePhoto() async {
    try {
      // On web, camera access might be limited
      if (kIsWeb) {
        // For web, we can still try to access camera through image picker
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (photo != null) {
          return File(photo.path);
        }
        return null;
      }

      // Check camera permission for mobile platforms
      final hasCameraPermission = await requestCameraPermission();
      if (!hasCameraPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick photo from gallery
  static Future<File?> pickFromGallery() async {
    try {
      // On web, permissions are handled by browser file dialog
      if (kIsWeb) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (photo != null) {
          return File(photo.path);
        }
        return null;
      }

      // Check photos permission for mobile platforms
      final hasPhotosPermission = await requestPhotosPermission();
      if (!hasPhotosPermission) {
        throw Exception('Photos permission denied');
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error picking photo from gallery: $e');
      return null;
    }
  }

  /// Show photo source selection dialog and return selected photo
  static Future<File?> selectPhoto({
    required Function() onCameraSelected,
    required Function() onGallerySelected,
  }) async {
    // This method should be called from a widget that can show dialogs
    // The actual dialog implementation will be in the UI components
    return null;
  }

  /// Save photo and return the saved path
  static Future<String?> savePhoto(File photo) async {
    try {
      final filename = '${_uuid.v4()}.jpg';
      final savedPath = await StorageService.savePhoto(photo, filename);
      return savedPath;
    } catch (e) {
      print('Error saving photo: $e');
      return null;
    }
  }

  /// Delete photo
  static Future<void> deletePhoto(String photoPath) async {
    try {
      await StorageService.deletePhoto(photoPath);
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  /// Check if file exists
  static Future<bool> photoExists(String photoPath) async {
    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      print('Error checking if photo exists: $e');
      return false;
    }
  }

  /// Get photo file from path
  static File? getPhotoFile(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }
    
    final file = File(photoPath);
    return file;
  }

  /// Compress photo if needed
  static Future<File?> compressPhoto(File photo, {int quality = 85}) async {
    try {
      // For now, we'll just return the original photo
      // In a more advanced implementation, you could use image compression libraries
      return photo;
    } catch (e) {
      print('Error compressing photo: $e');
      return photo;
    }
  }

  /// Get file size in bytes
  static Future<int> getPhotoSize(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting photo size: $e');
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    
    const List<String> suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  /// Check camera availability
  static Future<bool> isCameraAvailable() async {
    try {
      return true; // Assume camera is available
    } catch (e) {
      return false;
    }
  }

  /// Get photo thumbnail (for now, just return the original photo)
  static Future<File?> getPhotoThumbnail(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting photo thumbnail: $e');
      return null;
    }
  }
}