import 'package:dio/dio.dart';
import '../models/search_result.dart';

class LocationSearchService {
  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org/search';
  static final Dio _dio = Dio();
  static DateTime? _lastRequestTime;
  
  // Rate limiting: 1 request per second as per Nominatim usage policy
  static const Duration _rateLimitDelay = Duration(milliseconds: 1000);
  
  static Future<List<SearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty || query.trim().length < 3) {
      return [];
    }
    
    try {
      // Implement rate limiting
      await _respectRateLimit();
      
      final response = await _dio.get(
        nominatimBaseUrl,
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'limit': 8,
          'addressdetails': 1,
          'bounded': 0,
          'dedupe': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'TravelJournalApp/1.0 (Flutter App)', // Required by Nominatim
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      _lastRequestTime = DateTime.now();
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((item) {
          try {
            return SearchResult.fromJson(item);
          } catch (e) {
            print('Error parsing search result: $e');
            return null;
          }
        }).where((result) => result != null).cast<SearchResult>().toList();
      }
    } catch (e) {
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
            print('Search timeout: $e');
            break;
          case DioExceptionType.connectionError:
            print('Search connection error: $e');
            break;
          default:
            print('Search request error: $e');
        }
      } else {
        print('Search error: $e');
      }
    }
    return [];
  }
  
  static Future<void> _respectRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _rateLimitDelay) {
        final waitTime = _rateLimitDelay - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }
  }
  
  // Enhanced search for specific location types
  static Future<List<SearchResult>> searchLocationByType(
    String query, {
    String? locationType,
  }) async {
    String searchQuery = query.trim();
    
    // Add type-specific search hints
    if (locationType != null) {
      switch (locationType.toLowerCase()) {
        case 'restaurant':
          searchQuery += ' restaurant';
          break;
        case 'hotel':
          searchQuery += ' hotel';
          break;
        case 'attraction':
          searchQuery += ' tourist attraction';
          break;
        case 'city':
          searchQuery += ' city';
          break;
      }
    }
    
    return searchLocation(searchQuery);
  }
  
  // Get detailed information about a specific place
  static Future<SearchResult?> getPlaceDetails(
    double latitude, 
    double longitude
  ) async {
    try {
      await _respectRateLimit();
      
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'addressdetails': 1,
          'zoom': 14,
        },
        options: Options(
          headers: {
            'User-Agent': 'TravelJournalApp/1.0 (Flutter App)',
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      _lastRequestTime = DateTime.now();
      
      if (response.statusCode == 200 && response.data != null) {
        return SearchResult.fromJson(response.data);
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return null;
  }
}