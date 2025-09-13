import 'dart:convert';

class TravelLog {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? note;
  final String? photoPath; // Keep for backward compatibility
  final List<String> photoPaths; // New field for multiple photos
  final String? locationName;

  TravelLog({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.note,
    this.photoPath,
    this.photoPaths = const [],
    this.locationName,
  });

  TravelLog copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? note,
    String? photoPath,
    List<String>? photoPaths,
    String? locationName,
  }) {
    return TravelLog(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      photoPaths: photoPaths ?? this.photoPaths,
      locationName: locationName ?? this.locationName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
        'photoPath': photoPath,
        'photoPaths': photoPaths,
        'locationName': locationName,
      };

  factory TravelLog.fromJson(Map<String, dynamic> json) => TravelLog(
        id: json['id'],
        latitude: json['latitude'].toDouble(),
        longitude: json['longitude'].toDouble(),
        timestamp: DateTime.parse(json['timestamp']),
        note: json['note'],
        photoPath: json['photoPath'],
        photoPaths: json['photoPaths'] != null 
            ? List<String>.from(json['photoPaths']) 
            : (json['photoPath'] != null ? [json['photoPath']] : []), // Backward compatibility
        locationName: json['locationName'],
      );

  String toJsonString() => json.encode(toJson());

  factory TravelLog.fromJsonString(String jsonString) =>
      TravelLog.fromJson(json.decode(jsonString));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TravelLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper methods for photos
  List<String> get allPhotoPaths {
    final allPaths = <String>[];
    if (photoPaths.isNotEmpty) {
      allPaths.addAll(photoPaths);
    } else if (photoPath != null) {
      allPaths.add(photoPath!);
    }
    return allPaths;
  }

  bool get hasPhotos => allPhotoPaths.isNotEmpty;

  String? get primaryPhotoPath => allPhotoPaths.isNotEmpty ? allPhotoPaths.first : null;

  @override
  String toString() {
    return 'TravelLog{id: $id, latitude: $latitude, longitude: $longitude, timestamp: $timestamp, note: $note, photoPath: $photoPath, photoPaths: $photoPaths, locationName: $locationName}';
  }
}