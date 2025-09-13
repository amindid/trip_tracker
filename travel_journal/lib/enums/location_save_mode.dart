enum LocationSaveMode {
  currentLocation,
  manualSelection,
}

class LocationSelectionState {
  LocationSaveMode saveMode;
  double? selectedLatitude;
  double? selectedLongitude;
  bool isInSelectionMode;
  
  LocationSelectionState({
    this.saveMode = LocationSaveMode.currentLocation,
    this.selectedLatitude,
    this.selectedLongitude,
    this.isInSelectionMode = false,
  });
  
  LocationSelectionState copyWith({
    LocationSaveMode? saveMode,
    double? selectedLatitude,
    double? selectedLongitude,
    bool? isInSelectionMode,
  }) {
    return LocationSelectionState(
      saveMode: saveMode ?? this.saveMode,
      selectedLatitude: selectedLatitude ?? this.selectedLatitude,
      selectedLongitude: selectedLongitude ?? this.selectedLongitude,
      isInSelectionMode: isInSelectionMode ?? this.isInSelectionMode,
    );
  }
  
  void reset() {
    saveMode = LocationSaveMode.currentLocation;
    selectedLatitude = null;
    selectedLongitude = null;
    isInSelectionMode = false;
  }
  
  bool get hasSelectedLocation => selectedLatitude != null && selectedLongitude != null;
}