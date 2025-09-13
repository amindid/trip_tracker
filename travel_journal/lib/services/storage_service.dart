import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/travel_log.dart';

class StorageService {
  static const String _logsKey = 'travel_logs';
  static const String _photosDir = 'travel_photos';
  static const String _webPhotosKey = 'web_travel_photos';

  /// Save travel logs to SharedPreferences
  static Future<void> saveTravelLogs(List<TravelLog> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = logs.map((log) => log.toJson()).toList();
      await prefs.setString(_logsKey, json.encode(logsJson));
    } catch (e) {
      print('Error saving travel logs: $e');
      throw Exception('Failed to save travel logs');
    }
  }

  /// Load travel logs from SharedPreferences
  static Future<List<TravelLog>> loadTravelLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString(_logsKey);
      
      if (logsString == null || logsString.isEmpty) {
        return [];
      }

      final List<dynamic> logsJson = json.decode(logsString);
      return logsJson.map((logJson) => TravelLog.fromJson(logJson)).toList();
    } catch (e) {
      print('Error loading travel logs: $e');
      return [];
    }
  }

  /// Add a new travel log
  static Future<void> addTravelLog(TravelLog log) async {
    try {
      final logs = await loadTravelLogs();
      logs.add(log);
      await saveTravelLogs(logs);
    } catch (e) {
      print('Error adding travel log: $e');
      throw Exception('Failed to add travel log');
    }
  }

  /// Update an existing travel log
  static Future<void> updateTravelLog(TravelLog updatedLog) async {
    try {
      final logs = await loadTravelLogs();
      final index = logs.indexWhere((log) => log.id == updatedLog.id);
      
      if (index != -1) {
        logs[index] = updatedLog;
        await saveTravelLogs(logs);
      } else {
        throw Exception('Travel log not found');
      }
    } catch (e) {
      print('Error updating travel log: $e');
      throw Exception('Failed to update travel log');
    }
  }

  /// Delete a travel log
  static Future<void> deleteTravelLog(String logId) async {
    try {
      final logs = await loadTravelLogs();
      final logToDelete = logs.firstWhere(
        (log) => log.id == logId,
        orElse: () => throw Exception('Travel log not found'),
      );

      // Delete associated photos if they exist
      for (final photoPath in logToDelete.allPhotoPaths) {
        await deletePhoto(photoPath);
      }

      logs.removeWhere((log) => log.id == logId);
      await saveTravelLogs(logs);
    } catch (e) {
      print('Error deleting travel log: $e');
      throw Exception('Failed to delete travel log');
    }
  }

  /// Get application documents directory
  static Future<Directory> getApplicationDirectory() async {
    if (kIsWeb) {
      // On web, we don't use file system directories
      throw UnsupportedError('Directory operations not supported on web');
    }
    return await getApplicationDocumentsDirectory();
  }

  /// Get photos directory
  static Future<Directory> getPhotosDirectory() async {
    if (kIsWeb) {
      // On web, we don't use file system directories
      throw UnsupportedError('Directory operations not supported on web');
    }
    
    final appDir = await getApplicationDirectory();
    final photosDir = Directory('${appDir.path}/$_photosDir');
    
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    return photosDir;
  }

  /// Save photo to app directory and return the path
  static Future<String> savePhoto(File photo, String filename) async {
    try {
      if (kIsWeb) {
        // On web, we get the photo data directly from the path (which is already a blob URL)
        final photoPath = photo.path;
        
        final prefs = await SharedPreferences.getInstance();
        final webPhotos = prefs.getStringList(_webPhotosKey) ?? [];
        
        // Create a unique identifier for the photo and store the blob URL
        final photoId = 'photo_${DateTime.now().millisecondsSinceEpoch}_$filename';
        final photoData = '$photoId:$photoPath';
        
        webPhotos.add(photoData);
        await prefs.setStringList(_webPhotosKey, webPhotos);
        
        return photoId; // Return the photo ID instead of a path
      } else {
        // On mobile, use file system storage
        final photosDir = await getPhotosDirectory();
        final photoPath = '${photosDir.path}/$filename';
        
        await photo.copy(photoPath);
        return photoPath;
      }
    } catch (e) {
      print('Error saving photo: $e');
      throw Exception('Failed to save photo');
    }
  }

  /// Delete photo from app directory
  static Future<void> deletePhoto(String photoPath) async {
    try {
      if (kIsWeb) {
        // On web, remove photo from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final webPhotos = prefs.getStringList(_webPhotosKey) ?? [];
        
        // Remove the photo with matching ID
        webPhotos.removeWhere((photoData) => photoData.startsWith('$photoPath:'));
        await prefs.setStringList(_webPhotosKey, webPhotos);
      } else {
        // On mobile, delete file from file system
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error deleting photo: $e');
      // Don't throw exception for photo deletion errors
    }
  }

  /// Get all photos from travel logs
  static Future<List<String>> getAllPhotoPaths() async {
    try {
      final logs = await loadTravelLogs();
      final allPhotoPaths = <String>[];
      for (final log in logs) {
        allPhotoPaths.addAll(log.allPhotoPaths);
      }
      return allPhotoPaths;
    } catch (e) {
      print('Error getting photo paths: $e');
      return [];
    }
  }

  /// Export travel logs as JSON string
  static Future<String> exportTravelLogsAsJson() async {
    try {
      final logs = await loadTravelLogs();
      final logsJson = logs.map((log) => log.toJson()).toList();
      return json.encode(logsJson);
    } catch (e) {
      print('Error exporting travel logs: $e');
      throw Exception('Failed to export travel logs');
    }
  }

  /// Export travel logs as text string
  static Future<String> exportTravelLogsAsText() async {
    try {
      final logs = await loadTravelLogs();
      final buffer = StringBuffer();
      
      buffer.writeln('Travel Journal Export');
      buffer.writeln('Generated on: ${DateTime.now()}');
      buffer.writeln('Total logs: ${logs.length}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (int i = 0; i < logs.length; i++) {
        final log = logs[i];
        buffer.writeln('Entry ${i + 1}:');
        buffer.writeln('Date: ${log.timestamp}');
        buffer.writeln('Location: ${log.latitude}, ${log.longitude}');
        if (log.locationName != null) {
          buffer.writeln('Place: ${log.locationName}');
        }
        if (log.note != null && log.note!.isNotEmpty) {
          buffer.writeln('Note: ${log.note}');
        }
        if (log.photoPath != null) {
          buffer.writeln('Photo: Yes');
        }
        buffer.writeln('-' * 30);
        buffer.writeln();
      }

      return buffer.toString();
    } catch (e) {
      print('Error exporting travel logs as text: $e');
      throw Exception('Failed to export travel logs as text');
    }
  }

  /// Clear all travel logs (for testing or reset purposes)
  static Future<void> clearAllTravelLogs() async {
    try {
      // Delete all photos first
      final photoPaths = await getAllPhotoPaths();
      for (final photoPath in photoPaths) {
        await deletePhoto(photoPath);
      }

      // Clear the logs from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logsKey);
    } catch (e) {
      print('Error clearing travel logs: $e');
      throw Exception('Failed to clear travel logs');
    }
  }

  /// Get blob URL for web photo by ID
  static Future<String?> getWebPhotoData(String photoId) async {
    if (!kIsWeb) return null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final webPhotos = prefs.getStringList(_webPhotosKey) ?? [];
      
      for (final photoData in webPhotos) {
        if (photoData.startsWith('$photoId:')) {
          final blobUrl = photoData.substring(photoId.length + 1);
          return blobUrl;
        }
      }
      return null;
    } catch (e) {
      print('Error getting web photo data: $e');
      return null;
    }
  }

  /// Get storage usage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final logs = await loadTravelLogs();
      final photoPaths = await getAllPhotoPaths();
      
      int totalPhotoSize = 0;
      int validPhotos = 0;

      for (final photoPath in photoPaths) {
        final file = File(photoPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          totalPhotoSize += fileSize;
          validPhotos++;
        }
      }

      return {
        'totalLogs': logs.length,
        'totalPhotos': photoPaths.length,
        'validPhotos': validPhotos,
        'totalPhotoSizeBytes': totalPhotoSize,
        'totalPhotoSizeMB': (totalPhotoSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {
        'totalLogs': 0,
        'totalPhotos': 0,
        'validPhotos': 0,
        'totalPhotoSizeBytes': 0,
        'totalPhotoSizeMB': '0.00',
      };
    }
  }
}