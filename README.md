# Travel Journal

A Flutter mobile app that allows users to log their travel locations with GPS, date/time, notes, and photos. All data is stored locally and displayed on both a list and map view.

## Features

### Core Functionality
- **Log Location**: Capture current GPS coordinates with one tap
- **Photo Integration**: Take photos with camera or select from gallery
- **Notes**: Add text descriptions for each location
- **Local Storage**: All data stored locally using SharedPreferences
- **Three Main Views**:
  - **List View**: Scrollable list of all travel logs (newest first)
  - **Map View**: OpenStreetMap with location markers
  - **Photo Gallery**: Visual gallery of travel photos

### Enhanced Features
- **Search**: Filter travel logs by note text or location name
- **Edit Logs**: Modify notes and view detailed information
- **Delete Logs**: Swipe to delete or use detail screen options
- **Share Logs**: Export and share travel information
- **Distance Calculation**: Shows distance from current location
- **Photo Viewer**: Full-screen photo viewing with details
- **Offline Functionality**: Works completely offline
- **Device Preview**: Multi-device testing in VS Code without emulators

## Screenshots

The app includes:
- Clean Material Design UI with teal color scheme
- Card-based layouts for easy reading
- Intuitive bottom navigation
- Prominent floating action button for logging locations
- Interactive maps with colored markers based on recency
- Photo thumbnails and full-screen viewing

## Technical Details

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  geolocator: ^9.0.2        # GPS location services
  flutter_map: ^6.1.0      # OpenStreetMap integration
  latlong2: ^0.9.1          # Latitude/longitude utilities
  shared_preferences: ^2.2.2 # Local data persistence
  path_provider: ^2.1.1     # File system access
  image_picker: ^1.0.4      # Camera and gallery access
  permission_handler: ^11.0.1 # Runtime permissions
  intl: ^0.20.2             # Date/time formatting
  share_plus: ^7.2.1        # Sharing functionality
  http: ^1.1.0              # HTTP requests for geocoding
  uuid: ^4.5.1              # Unique ID generation
  device_preview: ^1.1.0    # Multi-device testing in VS Code

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### Data Model
```dart
class TravelLog {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? note;
  final String? photoPath;
  final String? locationName;
  
  // JSON serialization methods included
}
```

### App Architecture
- **Models**: TravelLog data class
- **Services**: 
  - LocationService (GPS functionality)
  - StorageService (local data persistence)
  - PhotoService (camera and gallery)
- **Screens**: 
  - HomeScreen (bottom navigation)
  - ListScreen (travel logs list)
  - MapScreen (interactive map)
  - PhotosScreen (photo gallery)
  - LogEntryScreen (add new logs)
  - LogDetailsScreen (view/edit details)
- **Widgets**: Reusable UI components

### Platform Setup

#### Android Permissions (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS Permissions (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to log your travel locations and show them on the map.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos for your travel memories.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select travel photos from your gallery.</string>
```

## Getting Started

1. **Clone the repository**
2. **Install dependencies**: `flutter pub get`
3. **Run the app**: `flutter run`

### Requirements
- Flutter SDK 3.9.2 or higher
- Dart SDK 2.17.0 or higher
- Android SDK (for Android builds)
- Xcode (for iOS builds)

## Device Preview - Multi-Device Testing in VS Code

The Travel Journal app includes **Device Preview** functionality for comprehensive multi-device testing directly in VS Code without needing emulators or physical devices.

### How to Use Device Preview

1. **Run with Web Target**:
   ```bash
   flutter run -d chrome
   ```

2. **Device Preview Interface**:
   - The app opens in Chrome with Device Preview controls
   - Select different devices from the dropdown menu
   - Available devices include iPhone 12/13/14, Samsung Galaxy, iPad, and more
   - Toggle between portrait and landscape orientations
   - Test different screen sizes and pixel ratios

### Testing Scenarios for Travel Journal

Use Device Preview to test how the app responds to different screen sizes:

#### **Mobile Phones (iPhone, Samsung)**
- **Location Logging Dialog**: Verify the dialog fits properly on smaller screens
- **Bottom Navigation**: Check navigation bar layout and accessibility
- **Travel Log Cards**: Ensure cards display properly in list view
- **Map View**: Test map controls and marker visibility
- **Photo Capture**: Verify camera UI is accessible and functional

#### **Tablets (iPad, Galaxy Tab)**
- **Responsive Layout**: Check how the app utilizes larger screen real estate
- **Map View**: Verify map markers and controls scale appropriately
- **Photo Gallery**: Test grid layout with more photos per row
- **Detail Screens**: Ensure content doesn't appear too stretched

#### **Orientation Testing**
- **Portrait Mode**: Standard mobile experience
- **Landscape Mode**: Verify all screens rotate properly and remain functional
- **Form Inputs**: Test location logging and note editing in both orientations

### Device Preview Benefits

- **No Emulator Setup**: Test multiple devices without installing emulators
- **Real-time Updates**: See code changes instantly across different device frames
- **Interactive Testing**: Click and interact with the app using mouse (simulates touch)
- **Quick Switching**: Rapidly test different screen sizes and orientations
- **Development Efficiency**: Debug responsive design issues quickly

### Usage in Development Workflow

1. **Write Code**: Make changes to Flutter components in VS Code
2. **Hot Reload**: See changes instantly in all device previews
3. **Test Responsive Design**: Verify layouts work on different screen sizes
4. **Debug Issues**: Quickly identify and fix device-specific problems
5. **UI Verification**: Ensure consistent user experience across devices

### Device Preview Integration

The app is wrapped with `DevicePreview` in `main.dart`:

```dart
void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Only in debug mode
      builder: (context) => const TravelJournalApp(),
    ),
  );
}
```

**Note**: Device Preview is only enabled in debug mode and will be disabled in release builds for optimal performance.

## Usage

### Logging a Location
1. Tap the "Log Location" floating action button
2. App automatically captures your current GPS coordinates
3. Optionally add a photo (camera or gallery)
4. Optionally add a note describing the location
5. Tap "Save" to store the travel log

### Viewing Your Logs
- **List Tab**: See all logs in chronological order with search functionality
- **Map Tab**: View all locations on an interactive map with color-coded markers
- **Photos Tab**: Browse a visual gallery of your travel photos

### Managing Logs
- Tap any log to view full details
- Edit notes directly in the detail screen
- Swipe to delete logs from the list
- Share logs as text via the system share sheet

## Map Features

- **OpenStreetMap Integration**: No API keys required
- **Color-coded Markers**: 
  - Red: Recent (< 1 week)
  - Orange: This month
  - Blue: This year
  - Purple: Older
- **Interactive Controls**: Zoom, pan, center on current location
- **Marker Popups**: Tap markers to see basic info and access full details

## Storage

All data is stored locally on your device:
- Travel logs: SharedPreferences (JSON format)
- Photos: App documents directory
- No cloud sync or external dependencies
- Complete privacy and offline functionality

## Development Features

- **Device Preview**: Test on different screen sizes
- **Error Handling**: Proper error messages and loading states
- **Permission Handling**: Runtime permission requests
- **Responsive Design**: Works on various screen sizes
- **Material 3**: Modern Material Design components

## Future Enhancements

Potential features for future versions:
- Cloud sync and backup
- Export to GPX/KML formats
- Trip grouping and organization
- Weather data integration
- Social sharing features
- Advanced search and filtering
- Photo editing capabilities

## License

This project is built as a complete example of a Flutter travel logging application with full source code available for learning and modification.