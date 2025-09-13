class SearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final String? city;
  final String? country;
  final String? state;
  
  SearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.city,
    this.country,
    this.state,
  });
  
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      type: json['type'] ?? 'location',
      city: json['address']?['city'] ?? 
            json['address']?['town'] ?? 
            json['address']?['village'],
      country: json['address']?['country'],
      state: json['address']?['state'] ?? json['address']?['province'],
    );
  }
  
  String get shortDescription {
    final parts = <String>[];
    
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    
    return parts.join(', ');
  }
  
  String get primaryName {
    final parts = displayName.split(',');
    return parts.isNotEmpty ? parts.first.trim() : displayName;
  }
}