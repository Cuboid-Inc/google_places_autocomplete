# Google Places Autocomplete

![Flutter 3.24+](https://img.shields.io/badge/Flutter-3.24+-blue)
[![pub package](https://img.shields.io/pub/v/google_places_autocomplete.svg?label=google_places_autocomplete&color=blue)](https://pub.dev/packages/google_places_autocomplete)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful, UI-agnostic Flutter package for Google Places API integration. Get autocomplete predictions with **distance from user**, detailed place information, and full control over your UI.

## ✨ Features

- 🎨 **UI-Agnostic** - Bring your own UI, we handle the data
- 📍 **Distance Support** - Show distance from user to each prediction
- 🔐 **Platform-Native API Keys** - Read from AndroidManifest/Info.plist (no hardcoded keys!)
- 🌍 **Cross-Platform** - Android, iOS
- ⚡ **Performance Optimized** - Built-in debouncing
- 🔧 **Highly Configurable** - Filter by country, place type, language

---

## 🚀 Quick Start

### 1. Platform Setup

**Android** - Add to `AndroidManifest.xml`:
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY" />
</application>
```

**iOS** - Add to `Info.plist`:
```xml
<key>GOOGLE_PLACES_API_KEY</key>
<string>YOUR_API_KEY</string>
```

### 2. Install

```yaml
dependencies:
  google_places_autocomplete: ^2.0.1
```

### 3. Use

```dart
import 'package:google_places_autocomplete/google_places_autocomplete.dart';

final places = GooglePlacesAutocomplete(  
  // Optional - enables distance display in predictions
  originLat: userLatitude,
  originLng: userLongitude,
  
  predictionsListener: (predictions) {
    for (final p in predictions) {
      print('${p.title} - ${p.distanceMeters}m away');
    }
  },
  loadingListener: (isLoading) => print('Loading: $isLoading'),
);

await places.initialize(
   // Optional - reads from platform config if not provided
  // apiKey: 'YOUR_KEY',
);  // Important: await this!
places.getPredictions('coffee shop');
```

---

## 📖 API Reference

### Constructor Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `predictionsListener` | `Function(List<Prediction>)` | ✅ | Callback for predictions |
| `loadingListener` | `Function(bool)` | ❌ | Loading state callback |
| `originLat` | `double?` | ❌ | User latitude for distance calculation |
| `originLng` | `double?` | ❌ | User longitude for distance calculation |
| `debounceTime` | `int` | ❌ | Debounce in ms (default: 300, min: 200) |
| `countries` | `List<String>?` | ❌ | Country codes e.g. `['us', 'ca']` |
| `primaryTypes` | `List<String>?` | ❌ | Place types e.g. `['restaurant']` |
| `language` | `String?` | ❌ | Language code e.g. `'en'` |

### Methods

```dart
// Initialize (required, async)
await places.initialize(
  // Optional - reads from platform config if not provided
  // apiKey: 'YOUR_KEY',
);

// Get predictions
places.getPredictions('search query');

// Get place details
final details = await places.getPredictionDetail('place_id');

// Update user location (for distance)
places.setOrigin(latitude: 37.7749, longitude: -122.4194);

// Clear origin (disable distance)
places.clearOrigin();
```

### Prediction Model

```dart
class Prediction {
  final String? placeId;       // Use with getPredictionDetail()
  final String? title;         // Main text
  final String? description;   // Secondary text
  final int? distanceMeters;   // Distance from origin (if set)
  final List<String>? types;   // Place types
}
```

### PlaceDetails Model

```dart
class PlaceDetails {
  final String? placeId;
  final String? name;
  final String? formattedAddress;
  final Location? location;              // .lat, .lng
  final List<AddressComponent>? addressComponents;  // Full list
  
  // Parsed from addressComponents:
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? streetAddress;
  final String? streetNumber;
  
  // Contact
  final String? nationalPhoneNumber;
  final String? internationalPhoneNumber;
  final String? googleMapsUri;
  final String? websiteUri;
  
  // Business info
  final double? rating;
  final int? userRatingsTotal;
  final String? businessStatus;  // OPERATIONAL, CLOSED_TEMPORARILY, etc.
  final List<String>? types;
  
  // Additional
  final int? utcOffset;
  final PlusCode? plusCode;      // .globalCode, .compoundCode
  final Viewport? viewport;      // .northeast, .southwest
}
```

### AddressComponent Model

```dart
class AddressComponent {
  final String longText;       // Full name: "California"
  final String? shortText;     // Abbreviated: "CA"
  final List<String> types;    // e.g., ["administrative_area_level_1"]
}
```

---

## 💡 Examples

### Display Distance Badge

```dart
ListTile(
  title: Text(prediction.title ?? ''),
  subtitle: Text(prediction.description ?? ''),
  trailing: prediction.distanceMeters != null
      ? Text(_formatDistance(prediction.distanceMeters!))
      : null,
);

String _formatDistance(int meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '$meters m';
}
```

### Filter by Country

```dart
GooglePlacesAutocomplete(
  countries: ['pk', 'ae'],  // Pakistan & UAE only
  predictionsListener: (p) => setState(() => predictions = p),
);
```

### Get Coordinates from Selection

```dart
onTap: () async {
  final details = await places.getPredictionDetail(prediction.placeId!);
  final lat = details?.location?.lat;
  final lng = details?.location?.lng;
  // Use coordinates...
}
```

---

## 📦 Android Release Configuration

If you encounter errors in release builds (like `ServiceConfigurationError` or missing classes or the predictions did not fetch in production), add these rules to your `android/app/proguard-rules.pro`:

```properties
# Keep custom plugin classes
-keep class com.cuboid.google_places_autocomplete.** { *; }

# Google Places SDK - Required to prevent R8 from stripping reflection-based classes
# This fixes: ServiceConfigurationError: Provider com.google.android.libraries.places.internal.u1 could not be instantiated
-keep class com.google.android.libraries.places.** { *; }
-keepclassmembers class com.google.android.libraries.places.** { *; }
-dontwarn com.google.android.libraries.places.**
```

---

## ⚠️ Breaking Changes

### v2.0.0
- **Minimum Android SDK**: 28 (was 23)
- **Minimum iOS**: 17.0
- **Java 17** required for Android builds

### v0.1.1

| Change | Before | After |
|--------|--------|-------|
| Listener names | `predictionsListner` | `predictionsListener` |
| | `loadingListner` | `loadingListener` |
| Initialize | `initialize()` (sync) | `await initialize()` (async) |
| API key | Required | Optional (platform fallback) |

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| No predictions | Ensure Places API is enabled in Google Cloud Console |
| No distance shown | Provide `originLat` and `originLng` |
| API key not found | Check platform manifest/plist configuration |

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
