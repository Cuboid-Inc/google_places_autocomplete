import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'google_places_autocomplete_method_channel.dart';
import 'model/place_details.dart';
import 'model/prediction.dart';

/// The platform interface for Google Places Autocomplete.
///
/// This abstract class defines the API that platform-specific implementations
/// must provide. It extends [PlatformInterface] to ensure proper platform
/// interface verification.
abstract class GooglePlacesAutocompletePlatform extends PlatformInterface {
  /// Constructs a GooglePlacesAutocompletePlatform.
  GooglePlacesAutocompletePlatform() : super(token: _token);

  static final Object _token = Object();

  static GooglePlacesAutocompletePlatform _instance =
      MethodChannelGooglePlacesAutocomplete();

  /// The default instance of [GooglePlacesAutocompletePlatform] to use.
  ///
  /// Defaults to [MethodChannelGooglePlacesAutocomplete].
  static GooglePlacesAutocompletePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GooglePlacesAutocompletePlatform] when
  /// they register themselves.
  static set instance(GooglePlacesAutocompletePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the client.
  ///
  /// [apiKey] is optional. On Android implementation, it can be read from Manifest.
  /// On iOS, it can be provided here or via AppDelegate.
  Future<void> initialize({String? apiKey}) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Returns a list of autocomplete predictions.
  Future<List<Prediction>> getPredictions({
    required String query,
    List<String>? countries,
    List<String>? placeTypes,
    double? originLat,
    double? originLng,
  }) {
    throw UnimplementedError('getPredictions() has not been implemented.');
  }

  /// Returns detailed information about a place.
  Future<PlaceDetails?> getPlaceDetails({
    required String placeId,
  }) {
    throw UnimplementedError('getPlaceDetails() has not been implemented.');
  }
}
