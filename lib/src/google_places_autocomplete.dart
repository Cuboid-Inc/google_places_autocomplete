import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'google_places_autocomplete_platform_interface.dart';
import 'model/place_details.dart';
import 'model/prediction.dart';

export 'model/place_details.dart';
export 'model/prediction.dart';

/// A service class to interact with the Google Places API via Native SDKs.
class GooglePlacesAutocomplete {
  /// Callback listener for delivering autocomplete predictions to the UI.
  final void Function(List<Prediction> predictions) predictionsListener;

  /// Callback listener for delivering loading status.
  final void Function(bool isLoading)? loadingListener;

  /// The time delay (in milliseconds) to debounce user input for predictions.
  final int debounceTime;

  /// A list of country codes to filter predictions (e.g. 'US', 'FR').
  final List<String>? countries;

  /// A list of place types to filter predictions.
  final List<String>? placeTypes;

  /// The latitude of orbit for distance calculation.
  double? originLat;

  /// The longitude of orbit for distance calculation.
  double? originLng;

  /// Internal Subject for debouncing.
  final _subject = PublishSubject<String>();
  StreamSubscription<String>? _subscription;

  bool _isInitialized = false;

  GooglePlacesAutocomplete({
    required this.predictionsListener,
    this.loadingListener,
    this.debounceTime = 300,
    this.countries,
    this.placeTypes,
    this.originLat,
    this.originLng,
  }) {
    _subscription = _subject.stream
        .distinct()
        .debounceTime(Duration(milliseconds: debounceTime))
        .listen(_fetchPredictions);
  }

  /// Updates the user's origin location for distance calculation.
  void setOrigin({required double latitude, required double longitude}) {
    originLat = latitude;
    originLng = longitude;
  }

  /// Clears the origin location. Predictions will no longer include distance.
  void clearOrigin() {
    originLat = null;
    originLng = null;
  }

  /// Initializes the native client.
  ///
  /// On Android, the API key is typically read from the Manifest.
  /// On iOS, you can provide it here if it's not set in AppDelegate.
  Future<void> initialize({String? apiKey}) async {
    await GooglePlacesAutocompletePlatform.instance.initialize(apiKey: apiKey);
    _isInitialized = true;
  }

  /// Adds a query to the debouncer.
  void getPredictions(String query) {
    if (query.trim().isEmpty) {
      predictionsListener([]);
      return;
    }
    _subject.add(query);
  }

  /// Internal method to fetch predictions from platform channel.
  Future<void> _fetchPredictions(String query) async {
    if (!_isInitialized) {
      debugPrint(
          "GooglePlacesAutocomplete: Warning - Not initialized. Call initialize() first.");
    }

    try {
      loadingListener?.call(true);
      final predictions =
          await GooglePlacesAutocompletePlatform.instance.getPredictions(
        query: query,
        countries: countries,
        placeTypes: placeTypes,
        originLat: originLat,
        originLng: originLng,
      );
      predictionsListener(predictions);
    } catch (e) {
      debugPrint("GooglePlacesAutocomplete Error: $e");
      predictionsListener([]);
    } finally {
      loadingListener?.call(false);
    }
  }

  /// Fetches detailed information for a place.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!_isInitialized) {
      debugPrint(
          "GooglePlacesAutocomplete: Warning - Not initialized. Call initialize() first.");
    }
    try {
      return await GooglePlacesAutocompletePlatform.instance
          .getPlaceDetails(placeId: placeId);
    } catch (e) {
      debugPrint("GooglePlacesAutocomplete Error: $e");
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subject.close();
  }
}
