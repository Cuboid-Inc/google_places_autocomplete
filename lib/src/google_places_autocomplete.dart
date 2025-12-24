import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'exceptions/places_exception.dart';
import 'google_places_autocomplete_platform_interface.dart';
import 'model/place_details.dart';
import 'model/prediction.dart';

export 'exceptions/places_exception.dart';
export 'model/place_details.dart';
export 'model/prediction.dart';

/// A service class to interact with Google Places API via Native SDKs.
///
/// This class provides autocomplete predictions and place details using
/// native Android (Places SDK) and iOS (GMSPlacesClient) implementations.
///
/// ## Quick Start
/// ```dart
/// final places = GooglePlacesAutocomplete(
///   predictionsListener: (predictions) {
///     for (final p in predictions) {
///       print('${p.title} - ${p.distanceMeters}m');
///     }
///   },
///   onError: (error) => print('Error: ${error.message}'),
/// );
/// await places.initialize();
/// places.getPredictions('coffee shop');
/// ```
///
/// ## Platform Setup
/// - **Android**: Add `com.google.android.geo.API_KEY` to AndroidManifest.xml
/// - **iOS**: Add `GOOGLE_PLACES_API_KEY` to Info.plist
///
/// ## Session Tokens
/// This package manages session tokens automatically to optimize billing.
/// A new session starts with each search, and ends when [getPlaceDetails]
/// is called.
///
/// ## Error Handling
/// Errors are delivered via the [onError] callback. The package provides
/// typed exceptions for different error scenarios:
/// - [NotInitializedException] - Client not initialized
/// - [ApiKeyException] - API key missing or invalid
/// - [PredictionException] - Autocomplete request failed
/// - [PlaceDetailsException] - Place details request failed
///
/// See also:
/// - [Prediction] for the autocomplete result model
/// - [PlaceDetails] for detailed place information
/// - [PlacesException] for the error handling base class
class GooglePlacesAutocomplete {
  /// Creates a new [GooglePlacesAutocomplete] instance.
  ///
  /// The [predictionsListener] is required and will receive prediction results.
  ///
  /// Optional parameters:
  /// - [loadingListener] - Receive loading state updates
  /// - [onError] - Receive error notifications
  /// - [debounceTime] - Debounce delay in milliseconds (default: 300)
  /// - [countries] - Filter by country codes
  /// - [placeTypes] - Filter by place types
  /// - [originLat], [originLng] - User location for distance calculation
  GooglePlacesAutocomplete({
    required this.predictionsListener,
    this.loadingListener,
    this.onError,
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

  /// Callback listener for delivering autocomplete predictions to the UI.
  ///
  /// This callback is invoked whenever predictions are received from the API,
  /// including an empty list when the query is cleared or no results are found.
  final void Function(List<Prediction> predictions) predictionsListener;

  /// Optional callback listener for delivering loading status.
  ///
  /// Use this to show/hide loading indicators in your UI.
  /// - `true` when a request is in progress
  /// - `false` when the request completes (success or failure)
  final void Function(bool isLoading)? loadingListener;

  /// Optional callback for error handling.
  ///
  /// This is called when any API operation fails. The [PlacesException]
  /// contains the error [PlacesException.message], [PlacesException.code],
  /// and optional [PlacesException.details].
  ///
  /// ## Example
  /// ```dart
  /// onError: (error) {
  ///   if (error is ApiKeyException) {
  ///     print('Check your API key configuration');
  ///   } else if (error is PredictionException) {
  ///     print('Search failed: ${error.message}');
  ///   }
  /// }
  /// ```
  final void Function(PlacesException error)? onError;

  /// The time delay (in milliseconds) to debounce user input for predictions.
  ///
  /// This prevents excessive API calls while the user is typing.
  /// Default is 300ms. Minimum recommended value is 200ms.
  final int debounceTime;

  /// A list of country codes to filter predictions (e.g. `['US', 'CA']`).
  ///
  /// Uses ISO 3166-1 Alpha-2 country codes. When specified, only places
  /// within these countries will be returned.
  final List<String>? countries;

  /// A list of place types to filter predictions.
  ///
  /// Examples: `['restaurant']`, `['geocode']`, `['establishment']`.
  /// See Google Places API documentation for available types.
  final List<String>? placeTypes;

  /// The latitude of the user's location for distance calculation.
  ///
  /// When both [originLat] and [originLng] are set, predictions will
  /// include [Prediction.distanceMeters] showing distance from this point.
  double? originLat;

  /// The longitude of the user's location for distance calculation.
  ///
  /// When both [originLat] and [originLng] are set, predictions will
  /// include [Prediction.distanceMeters] showing distance from this point.
  double? originLng;

  /// Internal Subject for debouncing.
  final _subject = PublishSubject<String>();
  StreamSubscription<String>? _subscription;

  bool _isInitialized = false;

  /// Whether the Places client has been successfully initialized.
  ///
  /// Returns `true` after [initialize] completes successfully.
  bool get isInitialized => _isInitialized;

  /// Updates the user's origin location for distance calculation.
  ///
  /// Call this when the user's location changes. Subsequent predictions
  /// will include [Prediction.distanceMeters] calculated from this point.
  ///
  /// ## Example
  /// ```dart
  /// // Update when user location changes
  /// places.setOrigin(latitude: 37.7749, longitude: -122.4194);
  /// ```
  void setOrigin({required double latitude, required double longitude}) {
    originLat = latitude;
    originLng = longitude;
  }

  /// Clears the origin location.
  ///
  /// After calling this, predictions will no longer include distance
  /// information ([Prediction.distanceMeters] will be null).
  void clearOrigin() {
    originLat = null;
    originLng = null;
  }

  /// Initializes the native Places client.
  ///
  /// This must be called before using [getPredictions] or [getPlaceDetails].
  /// The API key is resolved in this order:
  /// 1. [apiKey] parameter (if provided)
  /// 2. Android: `com.google.android.geo.API_KEY` from AndroidManifest.xml
  /// 3. iOS: `GOOGLE_PLACES_API_KEY` or `GooglePlacesAPIKey` from Info.plist
  ///
  /// Throws [ApiKeyException] if no API key is found.
  ///
  /// ## Example
  /// ```dart
  /// // Uses platform-configured API key
  /// await places.initialize();
  ///
  /// // Or provide explicitly
  /// await places.initialize(apiKey: 'YOUR_API_KEY');
  /// ```
  Future<void> initialize({String? apiKey}) async {
    try {
      await GooglePlacesAutocompletePlatform.instance
          .initialize(apiKey: apiKey);
      _isInitialized = true;
    } catch (e) {
      final exception = ApiKeyException(e.toString());
      onError?.call(exception);
      rethrow;
    }
  }

  /// Searches for place predictions matching the [query].
  ///
  /// Results are delivered asynchronously via [predictionsListener].
  /// The search is automatically debounced based on [debounceTime].
  ///
  /// If [query] is empty or whitespace-only, an empty list is returned
  /// immediately without making an API call.
  ///
  /// ## Example
  /// ```dart
  /// // In your TextField onChanged:
  /// onChanged: (value) => places.getPredictions(value),
  /// ```
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
      const exception = NotInitializedException();
      onError?.call(exception);
      predictionsListener([]);
      return;
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
      final exception = PredictionException(e.toString());
      onError?.call(exception);
      predictionsListener([]);
    } finally {
      loadingListener?.call(false);
    }
  }

  /// Fetches detailed information for a place by its [placeId].
  ///
  /// The [placeId] is obtained from [Prediction.placeId] after a user
  /// selects a prediction.
  ///
  /// Returns [PlaceDetails] on success, or `null` if the request fails.
  /// Errors are reported via [onError].
  ///
  /// **Note**: Calling this method consumes the session token, which
  /// optimizes billing by grouping the autocomplete + details as one session.
  ///
  /// ## Example
  /// ```dart
  /// onTap: () async {
  ///   final details = await places.getPlaceDetails(prediction.placeId!);
  ///   if (details != null) {
  ///     print('Selected: ${details.name}');
  ///     print('Location: ${details.location?.lat}, ${details.location?.lng}');
  ///   }
  /// }
  /// ```
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!_isInitialized) {
      const exception = NotInitializedException();
      onError?.call(exception);
      return null;
    }
    try {
      return await GooglePlacesAutocompletePlatform.instance
          .getPlaceDetails(placeId: placeId);
    } catch (e) {
      final exception = PlaceDetailsException(e.toString());
      onError?.call(exception);
      return null;
    }
  }

  /// Disposes of resources used by this instance.
  ///
  /// Call this when you're done using the autocomplete service,
  /// typically in your widget's `dispose` method.
  ///
  /// ## Example
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _placesService.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    _subscription?.cancel();
    _subject.close();
  }
}
