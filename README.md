# Travel Journal App

A Flutter app for tracking your travel locations with GPS, photos, and notes.

## Features

- 📍 **Log locations** with GPS coordinates
- 📷 **Add photos** from camera or gallery  
- 📝 **Write notes** for each location
- 🗺️ **Interactive map** with location markers
- 🔍 **Search locations** by name (cities, landmarks, addresses)
- 📱 **Offline storage** - all data stays on your device

## Quick Start

1. **Install Flutter** (if not already installed)
2. **Clone this repository**
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run the app:**
   ```bash
   flutter run
   ```

## How to Use

### Log a New Location
1. Tap the **+** button
2. Allow GPS permission when prompted
3. Add a photo (optional)
4. Write a note (optional)
5. Tap **Save**

### Search for Locations
1. Go to the **Map** tab
2. Tap the **🔍** search button in the header
3. Type a location name (e.g., "Paris", "Eiffel Tower")
4. Select from search results
5. Tap **Save Here** to log that location

### View Your Travels
- **List**: See all locations in chronological order
- **Map**: View locations on an interactive map with color-coded markers
- **Photos**: Browse your travel photos

## Map Legend

- 🔴 **Red**: Recent (< 1 week)
- 🟠 **Orange**: This month  
- 🔵 **Blue**: This year
- 🟣 **Purple**: Older

## Requirements

- Flutter 3.9.2+
- Android/iOS device or emulator
- GPS and camera permissions

## Key Dependencies

- `flutter_map` - Interactive maps
- `geolocator` - GPS location services
- `image_picker` - Camera and photo gallery
- `dio` - Location search API
- `shared_preferences` - Local data storage


---

**Built with Flutter** 🚀
<img width="457" height="928" alt="Screenshot from 2025-09-13 06-58-40" src="https://github.com/user-attachments/assets/e9a7acc3-fd7c-43f6-8272-73d85670de0e" />
<img width="457" height="928" alt="Screenshot from 2025-09-13 07-03-32" src="https://github.com/user-attachments/assets/894a0cc9-a52b-4d71-b01d-dd56a54512e7" />
<img width="457" height="928" alt="Screenshot from 2025-09-13 07-06-20" src="https://github.com/user-attachments/assets/3e209e62-5260-4d1f-b96b-f8de1c0ee4bf" />
<img width="460" height="928" alt="Screenshot from 2025-09-13 07-07-23" src="https://github.com/user-attachments/assets/956290d4-fe34-4689-ad05-a30a6d0a2f87" />
<img width="460" height="928" alt="Screenshot from 2025-09-13 07-07-42" src="https://github.com/user-attachments/assets/606a9644-e2dd-4bcf-805f-694a8d6b2050" />

