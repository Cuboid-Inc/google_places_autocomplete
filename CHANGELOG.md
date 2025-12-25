# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-12-25

### 🚀 Major SDK Upgrade

- **Android SDK**: Upgraded from `4.1.0` → `5.1.1` (Places SDK for Android)
- **iOS SDK**: Upgraded from `9.2.0` → `10.6.0` (GooglePlaces)
- **Android Gradle Plugin**: Upgraded to `8.7.3`
- **Kotlin**: Upgraded to `2.1.0`
- **Java Target**: Upgraded from Java 8 → Java 17

### ✨ New Features

- **Complete Address Components** - `PlaceDetails` now includes full `addressComponents` list with:
  - `AddressComponent` model: `longText`, `shortText`, `types`
  - Pre-parsed fields: `city`, `state`, `zipCode`, `country`, `streetAddress`, `streetNumber`
- **New PlaceDetails fields**:
  - `googleMapsUri` - Direct link to Google Maps
  - `nationalPhoneNumber` / `internationalPhoneNumber` - Proper phone formats
  - `businessStatus` - OPERATIONAL, CLOSED_TEMPORARILY, CLOSED_PERMANENTLY
  - `types` - Place type list
  - `utcOffset` - UTC offset in minutes
  - `plusCode` - Plus Code with `globalCode` and `compoundCode`
  - `viewport` - Map viewport bounds

### 🔧 Platform Requirements

- **Android**: minSdk 28, compileSdk 35
- **iOS**: iOS 17.0+

---

## [1.0.0] - 2025-12-24

### 🏗 Native SDK Migration

- **Android**: Migrated to `PlacesClient` (Google Places SDK for Android).
- **iOS**: Migrated to `GMSPlacesClient` (Google Places SDK for iOS).
- **Session Tokens**: Implemented strict Session Token management to optimize billing (reduces cost by grouping autocomplete queries).
- **API Key Security**: Supports restricting API keys to Android apps (SHA-1) and iOS apps (Bundle ID) when using native SDKs.

## [0.1.1] - 2025-12-24

### 🚀 New Features

- **Distance from User** - Predictions now include `distanceMeters` when you provide user's origin location via `originLat`/`originLng` parameters
- **Platform-Native API Key** - Automatically reads API key from:
  - Android: `com.google.android.geo.API_KEY` in `AndroidManifest.xml`
  - iOS: `GOOGLE_PLACES_API_KEY` in `Info.plist`
- **Dynamic Origin Update** - New `setOrigin()` and `clearOrigin()` methods to update user location after initialization

### ⚠️ Breaking Changes

- **Listener callback names fixed** (typo correction):
  - `predictionsListner` → `predictionsListener`
  - `loadingListner` → `loadingListener`
- **`initialize()` is now async** - Must use `await initialize()` instead of sync call
- **`apiKey` is now optional** - Package attempts to read from platform config first, falls back to provided key

### Migration Guide

**Before (v0.1.0):**
```dart
final places = GooglePlacesAutocomplete(
  apiKey: 'YOUR_KEY',  // Required
  predictionsListner: (p) => ...,  // Typo
  loadingListner: (l) => ...,      // Typo
);
places.initialize();  // Sync
```

**After (v0.1.1):**
```dart
final places = GooglePlacesAutocomplete(
  // apiKey optional - reads from AndroidManifest/Info.plist
  originLat: userLat,  // NEW: for distance
  originLng: userLng,  // NEW: for distance
  predictionsListener: (p) => ...,  // Fixed spelling
  loadingListener: (l) => ...,      // Fixed spelling
);
await places.initialize();  // Async!
```

---

## [0.1.0] - 2025-05-29

### Production Release

- Fixed cross-platform compatibility issues with Dio HTTP client
- Improved HTTP client security with proper certificate handling
- Enhanced error handling and logging
- Added comprehensive documentation
- Optimized for latest Flutter versions

---

## [0.0.6] - 2025-05-28

### Platform Compatibility

- Fixed BrowserHttpClientAdapter issue for web platforms
- Updated dependencies for latest Flutter compatibility

---

## [0.0.5] - 2025-05-27

### Minor Improvements

- Enhanced error handling
- Updated documentation

---

## [0.0.4]

### Update README & Documentation

- Update README file and some package documentation.

---

## [0.0.3]

### Add Listener for Prediction Loading

- Implement a nullable listener to show loading status of predictions.

---

## [0.0.2]

### Update README

- Update README file.

---

## [0.0.1]

### Initial Release

- First release of `google_places_autocomplete`, providing basic functionality.
