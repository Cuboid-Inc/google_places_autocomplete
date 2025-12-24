import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'google_places_autocomplete_platform_interface.dart';
import 'model/place_details.dart';
import 'model/prediction.dart';

/// An implementation of [GooglePlacesAutocompletePlatform] that uses method channels.
class MethodChannelGooglePlacesAutocomplete
    extends GooglePlacesAutocompletePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('com.cuboid.google_places_autocomplete');

  @override
  Future<void> initialize({String? apiKey}) async {
    await methodChannel.invokeMethod<void>('initialize', {'apiKey': apiKey});
  }

  @override
  Future<List<Prediction>> getPredictions({
    required String query,
    List<String>? countries,
    List<String>? placeTypes,
    double? originLat,
    double? originLng,
  }) async {
    final result =
        await methodChannel.invokeMethod<List<dynamic>>('getPredictions', {
      'query': query,
      'countries': countries,
      'placeTypes': placeTypes,
      'originLat': originLat,
      'originLng': originLng,
    });

    if (result == null) return [];

    return result
        .map((e) => Prediction.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<PlaceDetails?> getPlaceDetails({required String placeId}) async {
    final result = await methodChannel
        .invokeMethod<Map<dynamic, dynamic>>('getPlaceDetails', {
      'placeId': placeId,
    });

    if (result == null) return null;

    return PlaceDetails.fromMap(Map<String, dynamic>.from(result));
  }
}
