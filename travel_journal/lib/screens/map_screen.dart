import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/travel_log.dart';
import '../models/search_result.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../enums/location_save_mode.dart';
import '../widgets/search_location_widget.dart';
import 'log_details_screen.dart';
import 'log_entry_screen.dart';

class MapScreen extends StatefulWidget {
  final LocationSelectionState locationSelectionState;
  final Function(double, double)? onLocationSelected;
  final VoidCallback? onSelectionModeExited;

  const MapScreen({
    super.key,
    required this.locationSelectionState,
    this.onLocationSelected,
    this.onSelectionModeExited,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  List<TravelLog> _logs = [];
  bool _isLoading = true;
  MapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  Marker? _searchResultMarker;
  Timer? _searchMarkerTimer;
  bool _showSearchOverlay = false;
  
  // Default map center (world view)
  static const LatLng _defaultCenter = LatLng(20.0, 0.0);
  static const double _defaultZoom = 2.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadLogs();
    _getCurrentLocation();
  }

  // Method to refresh logs from external calls
  void refreshLogs() {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await StorageService.loadTravelLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });

      // Fit bounds to show all markers
      if (logs.isNotEmpty) {
        _fitBoundsToMarkers();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _fitBoundsToMarkers() {
    if (_logs.isEmpty || _mapController == null) return;

    double minLat = _logs.first.latitude;
    double maxLat = _logs.first.latitude;
    double minLng = _logs.first.longitude;
    double maxLng = _logs.first.longitude;

    for (final log in _logs) {
      minLat = minLat < log.latitude ? minLat : log.latitude;
      maxLat = maxLat > log.latitude ? maxLat : log.latitude;
      minLng = minLng < log.longitude ? minLng : log.longitude;
      maxLng = maxLng > log.longitude ? maxLng : log.longitude;
    }

    // Add padding to the bounds
    const padding = 0.01;
    final bounds = LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );

    _mapController!.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _centerOnCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.move(_currentLocation!, 15.0);
    }
  }

  void _showAllMarkers() {
    if (_logs.isNotEmpty) {
      _fitBoundsToMarkers();
    }
  }

  void _toggleSearchOverlay() {
    setState(() {
      _showSearchOverlay = !_showSearchOverlay;
    });
  }

  Color _getMarkerColor(DateTime timestamp) {
    final now = DateTime.now();
    final daysDifference = now.difference(timestamp).inDays;
    
    if (daysDifference < 7) {
      return Colors.red; // Recent (less than a week)
    } else if (daysDifference < 30) {
      return Colors.orange; // This month
    } else if (daysDifference < 365) {
      return Colors.blue; // This year
    } else {
      return Colors.purple; // Older
    }
  }

  List<Marker> _buildMarkers() {
    final markers = _logs.map((log) {
      final markerColor = _getMarkerColor(log.timestamp);
      
      return Marker(
        point: LatLng(log.latitude, log.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            if (!widget.locationSelectionState.isInSelectionMode) {
              _showLogDetailsBottomSheet(log);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();

    // Add temporary selection marker if in selection mode and location is selected
    if (widget.locationSelectionState.isInSelectionMode && 
        widget.locationSelectionState.hasSelectedLocation) {
      markers.add(
        Marker(
          point: LatLng(
            widget.locationSelectionState.selectedLatitude!,
            widget.locationSelectionState.selectedLongitude!,
          ),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Marker> _buildCurrentLocationMarker() {
    if (_currentLocation == null) return [];
    
    return [
      Marker(
        point: _currentLocation!,
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    ];
  }

  void _showLogDetailsBottomSheet(TravelLog log) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _getMarkerColor(log.timestamp),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.locationName ?? 
                    LocationService.formatCoordinates(log.latitude, log.longitude),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy HH:mm').format(log.timestamp),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (log.note != null && log.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                log.note!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LogDetailsScreen(log: log),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadLogs(); // Refresh if log was modified
                      }
                    });
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateOverlay() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No travel logs yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Use the + button to log your current location or select a location on the map!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Legend',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              _buildLegendItem(Colors.red, 'Recent'),
              _buildLegendItem(Colors.orange, 'This month'),
              _buildLegendItem(Colors.blue, 'This year'),
              _buildLegendItem(Colors.purple, 'Older'),
              if (widget.locationSelectionState.isInSelectionMode) ...[
                const SizedBox(height: 3),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                _buildLegendItem(Colors.orange, 'Selected'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionModeOverlay() {
    if (!widget.locationSelectionState.isInSelectionMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.withOpacity(0.9),
              Colors.orange.withOpacity(0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap anywhere on the map to select a location',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onSelectionModeExited,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                tooltip: 'Cancel selection',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _onLocationSearched(SearchResult searchResult) {
    final location = LatLng(searchResult.latitude, searchResult.longitude);
    _animateToLocation(location, zoom: 15.0);
    _showSearchResultMarker(location);
    _showLocationPreview(searchResult);
    
    // Close search overlay after selection
    setState(() {
      _showSearchOverlay = false;
    });
  }

  void _animateToLocation(LatLng location, {double zoom = 15.0}) {
    _mapController?.move(location, zoom);
  }

  void _showSearchResultMarker(LatLng location) {
    // Cancel existing timer
    _searchMarkerTimer?.cancel();
    
    setState(() {
      _searchResultMarker = Marker(
        point: location,
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.search,
            color: Colors.white,
            size: 30,
          ),
        ),
      );
    });
    
    // Remove search marker after 8 seconds
    _searchMarkerTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _searchResultMarker = null;
        });
      }
    });
  }

  void _showLocationPreview(SearchResult searchResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Location info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          searchResult.primaryName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (searchResult.shortDescription.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            searchResult.shortDescription,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveLocationFromSearch(searchResult);
                      },
                      icon: const Icon(Icons.add_location),
                      label: const Text('Save Here'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveLocationFromSearch(SearchResult searchResult) {
    final location = LatLng(searchResult.latitude, searchResult.longitude);
    
    // Call the location selection callback if available (for selection mode)
    if (widget.locationSelectionState.isInSelectionMode) {
      widget.onLocationSelected?.call(searchResult.latitude, searchResult.longitude);
    } else {
      // Navigate to LogEntryScreen with the searched location coordinates
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogEntryScreen(
            manualLatitude: searchResult.latitude,
            manualLongitude: searchResult.longitude,
          ),
        ),
      ).then((result) {
        if (result == true) {
          // Refresh logs if a new log was saved
          _loadLogs();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map (${_logs.length} locations)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearchOverlay,
            tooltip: 'Search Locations',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnCurrentLocation,
            tooltip: 'My Location',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _showAllMarkers,
            tooltip: 'Show All',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Full screen map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _logs.isNotEmpty 
                        ? LatLng(_logs.first.latitude, _logs.first.longitude)
                        : _currentLocation ?? _defaultCenter,
                    initialZoom: _logs.isNotEmpty ? 10.0 : (_currentLocation != null ? 15.0 : _defaultZoom),
                    minZoom: 1.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) {
                      if (widget.locationSelectionState.isInSelectionMode) {
                        widget.onLocationSelected?.call(point.latitude, point.longitude);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.travel_journal',
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        ..._buildMarkers(),
                        ..._buildCurrentLocationMarker(),
                        if (_searchResultMarker != null) _searchResultMarker!,
                      ],
                    ),
                  ],
                ),
                
                // Search overlay on top of map (only when active)
                if (_showSearchOverlay)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header with close button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Search Locations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () => setState(() => _showSearchOverlay = false),
                                  tooltip: 'Close Search',
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(
                            height: 1,
                            color: Colors.grey[200],
                          ),
                          // Search widget
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SearchLocationWidget(
                              onLocationSelected: _onLocationSearched,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (_logs.isNotEmpty || widget.locationSelectionState.isInSelectionMode) _buildLegend(),
                _buildSelectionModeOverlay(),
                if (_logs.isEmpty && !widget.locationSelectionState.isInSelectionMode) _buildEmptyStateOverlay(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchMarkerTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}