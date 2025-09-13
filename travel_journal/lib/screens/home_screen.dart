import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'photos_screen.dart';
import 'log_entry_screen.dart';
import '../enums/location_save_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ListScreenState> _listScreenKey = GlobalKey<ListScreenState>();
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();
  final GlobalKey<PhotosScreenState> _photosScreenKey = GlobalKey<PhotosScreenState>();
  LocationSelectionState _locationSelectionState = LocationSelectionState();

  List<Widget> get _screens => [
    ListScreen(key: _listScreenKey),
    MapScreen(
      key: _mapScreenKey,
      locationSelectionState: _locationSelectionState,
      onLocationSelected: _onLocationSelected,
      onSelectionModeExited: _onSelectionModeExited,
    ),
    PhotosScreen(key: _photosScreenKey),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showLogEntryScreen({double? latitude, double? longitude}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEntryScreen(
          manualLatitude: latitude,
          manualLongitude: longitude,
        ),
        fullscreenDialog: true,
      ),
    ).then((result) {
      // Refresh all screens if a new log was added
      if (result == true) {
        _listScreenKey.currentState?.refreshLogs();
        _mapScreenKey.currentState?.refreshLogs();
        _photosScreenKey.currentState?.refreshPhotos();
        // Exit selection mode if we were in it
        if (_locationSelectionState.isInSelectionMode) {
          _onSelectionModeExited();
        }
      }
    });
  }

  void _enterMapSelectionMode() {
    setState(() {
      _locationSelectionState = _locationSelectionState.copyWith(
        saveMode: LocationSaveMode.manualSelection,
        isInSelectionMode: true,
        selectedLatitude: null,
        selectedLongitude: null,
      );
      _currentIndex = 1; // Switch to Map tab
    });
  }

  void _onLocationSelected(double latitude, double longitude) {
    setState(() {
      _locationSelectionState = _locationSelectionState.copyWith(
        selectedLatitude: latitude,
        selectedLongitude: longitude,
      );
    });
    
    // Show confirmation dialog or open log entry screen directly
    _showLocationConfirmationDialog(latitude, longitude);
  }

  void _onSelectionModeExited() {
    setState(() {
      _locationSelectionState.reset();
    });
  }

  void _showLocationConfirmationDialog(double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Selected Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Do you want to save this location as a travel log?'),
            const SizedBox(height: 8),
            Text(
              'Latitude: ${latitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Longitude: ${longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onSelectionModeExited();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showLogEntryScreen(latitude: latitude, longitude: longitude);
            },
            child: const Text('Save Location'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            activeIcon: Icon(Icons.list_alt),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.add_event,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        tooltip: 'Add Travel Log',
        heroTag: 'speedDial',
        children: [
          SpeedDialChild(
            child: const Icon(Icons.my_location),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            label: 'Log Current Location',
            onTap: () => _showLogEntryScreen(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.map),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onTertiary,
            label: 'Select on Map',
            onTap: _enterMapSelectionMode,
          ),
        ],
      ),
    );
  }
}