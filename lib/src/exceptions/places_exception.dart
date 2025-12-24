/// Base exception for all Google Places API errors.
///
/// This exception provides a consistent error structure across all
/// Places API operations. Use the specific subclasses for more
/// granular error handling.
///
/// ## Example
/// ```dart
/// try {
///   await places.initialize();
/// } on PlacesException catch (e) {
///   print('Places Error: ${e.code} - ${e.message}');
/// }
/// ```
class PlacesException implements Exception {

  /// Creates a [PlacesException] with the given [message].
  ///
  /// Optionally provide a [code] and [details] for more context.
  const PlacesException(
    this.message, {
    this.code,
    this.details,
  });
  /// Human-readable error message describing what went wrong.
  final String message;

  /// Error code from the native SDK or internal error identifier.
  ///
  /// Common codes include:
  /// - `MISSING_API_KEY` - API key not found
  /// - `NOT_INITIALIZED` - Client not initialized
  /// - `PREDICTION_ERROR` - Autocomplete request failed
  /// - `PLACE_DETAILS_ERROR` - Place details request failed
  final String? code;

  /// Additional error details from the native platform.
  ///
  /// This may contain stack traces or platform-specific error objects.
  final dynamic details;

  @override
  String toString() {
    if (code != null) {
      return 'PlacesException($code): $message';
    }
    return 'PlacesException: $message';
  }
}

/// Thrown when the Places client has not been initialized.
///
/// This exception occurs when you attempt to call [getPredictions] or
/// [getPlaceDetails] before calling [initialize].
///
/// ## Example
/// ```dart
/// final places = GooglePlacesAutocomplete(...);
/// // Forgot to call initialize()!
/// places.getPredictions('coffee'); // Throws NotInitializedException
/// ```
class NotInitializedException extends PlacesException {
  /// Creates a [NotInitializedException].
  const NotInitializedException([
    super.message = 'Places client not initialized. Call initialize() first.',
  ]) : super(code: 'NOT_INITIALIZED');
}

/// Thrown when the API key is missing or invalid.
///
/// Ensure you have configured your API key in:
/// - **Android**: `AndroidManifest.xml` with key `com.google.android.geo.API_KEY`
/// - **iOS**: `Info.plist` with key `GOOGLE_PLACES_API_KEY`
///
/// Or pass it directly to [initialize]:
/// ```dart
/// await places.initialize(apiKey: 'YOUR_API_KEY');
/// ```
class ApiKeyException extends PlacesException {
  /// Creates an [ApiKeyException].
  const ApiKeyException([
    super.message = 'API key not found or invalid.',
  ]) : super(code: 'MISSING_API_KEY');
}

/// Thrown when fetching autocomplete predictions fails.
///
/// This can happen due to:
/// - Network connectivity issues
/// - Invalid query parameters
/// - API quota exceeded
/// - Places API not enabled in Google Cloud Console
class PredictionException extends PlacesException {
  /// Creates a [PredictionException] with the given [message].
  const PredictionException(
    super.message, {
    String? code,
    super.details,
  }) : super(code: code ?? 'PREDICTION_ERROR');
}

/// Thrown when fetching place details fails.
///
/// This can happen due to:
/// - Invalid place ID
/// - Network connectivity issues
/// - API quota exceeded
/// - Place no longer exists
class PlaceDetailsException extends PlacesException {
  /// Creates a [PlaceDetailsException] with the given [message].
  const PlaceDetailsException(
    super.message, {
    String? code,
    super.details,
  }) : super(code: code ?? 'PLACE_DETAILS_ERROR');
}
