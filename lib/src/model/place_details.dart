/// Represents the detailed information about a place fetched from
/// the Google Places API.
///
/// This model contains comprehensive place information including name,
/// address, location coordinates, contact details, and ratings.
///
/// ## Example
/// ```dart
/// final details = await places.getPlaceDetails(prediction.placeId!);
/// if (details != null) {
///   print('Name: ${details.name}');
///   print('Address: ${details.formattedAddress}');
///   print('Location: ${details.location?.lat}, ${details.location?.lng}');
///   print('Rating: ${details.rating}');
/// }
/// ```
class PlaceDetails {

  /// Constructor for creating a [PlaceDetails] instance.
  const PlaceDetails({
    this.placeId,
    this.name,
    this.nationalPhoneNumber,
    this.internationalPhoneNumber,
    this.formattedPhoneNumber,
    this.formattedAddress,
    this.streetAddress,
    this.streetNumber,
    this.city,
    this.state,
    this.region,
    this.zipCode,
    this.country,
    this.location,
    this.googleMapsUri,
    this.websiteUri,
    this.website,
    this.rating,
    this.userRatingsTotal,
    this.geometry,
  });

  /// Creates a [PlaceDetails] from a platform channel response map.
  factory PlaceDetails.fromMap(Map<dynamic, dynamic> map) {
    // Safely extract address components list
    final rawAddressComponents = map['addressComponents'];
    final List<dynamic>? addressComponents =
        rawAddressComponents is List ? rawAddressComponents : null;

    String? extractAddressComponent(String type) {
      if (addressComponents == null) return null;
      for (var component in addressComponents) {
        if (component is! Map) continue;
        final rawTypes = component['types'];
        final List<dynamic>? types = rawTypes is List ? rawTypes : null;
        if (types != null && types.contains(type)) {
          return component['longText'] as String?;
        }
      }
      return null;
    }

    // Safely extract location
    Location? location;
    final rawLocation = map['location'];
    if (rawLocation != null && rawLocation is Map) {
      location = Location.fromMap(Map<String, dynamic>.from(rawLocation));
    }

    // Safely extract geometry
    Geometry? geometry;
    final rawGeometry = map['geometry'];
    if (rawGeometry != null && rawGeometry is Map) {
      geometry = Geometry.fromJson(Map<String, dynamic>.from(rawGeometry));
    }

    return PlaceDetails(
      placeId: map['placeId'] as String?,
      name: map['name'] as String?,
      nationalPhoneNumber: map['nationalPhoneNumber'] as String?,
      internationalPhoneNumber: map['internationalPhoneNumber'] as String?,
      formattedPhoneNumber: map['formattedPhoneNumber'] as String?,
      formattedAddress: map['formattedAddress'] as String?,
      streetAddress: extractAddressComponent('route'),
      streetNumber: extractAddressComponent('street_number'),
      city: extractAddressComponent('locality'),
      state: extractAddressComponent('administrative_area_level_1'),
      region: extractAddressComponent('administrative_area_level_2'),
      zipCode: extractAddressComponent('postal_code'),
      country: extractAddressComponent('country'),
      location: location,
      googleMapsUri: map['googleMapsUri'] as String?,
      websiteUri: map['websiteUri'] as String?,
      website: map['website'] as String?,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      userRatingsTotal: map['userRatingsTotal'] is int
          ? map['userRatingsTotal'] as int
          : null,
      geometry: geometry,
    );
  }
  /// The unique identifier of the place.
  final String? placeId;

  /// The name of the place.
  final String? name;

  /// The national format phone number of the place.
  final String? nationalPhoneNumber;

  /// The international format phone number of the place.
  final String? internationalPhoneNumber;

  /// The formatted phone number of the place.
  final String? formattedPhoneNumber;

  /// The formatted address of the place.
  final String? formattedAddress;

  /// The street address of the place (e.g., "Main St").
  final String? streetAddress;

  /// The street number of the place (e.g., "123").
  final String? streetNumber;

  /// The city where the place is located.
  final String? city;

  /// The state or province where the place is located.
  final String? state;

  /// The region or administrative area where the place is located.
  final String? region;

  /// The postal or zip code of the place.
  final String? zipCode;

  /// The country where the place is located.
  final String? country;

  /// The location coordinates of the place.
  final Location? location;

  /// The Google Maps URL for the place.
  final String? googleMapsUri;

  /// The website URL associated with the place.
  final String? websiteUri;

  /// The website URL of the place (alias for websiteUri).
  final String? website;

  /// The rating of the place (0.0 to 5.0).
  final double? rating;

  /// The total number of user ratings for the place.
  final int? userRatingsTotal;

  /// The geometry information of the place (contains location).
  final Geometry? geometry;

  /// Creates a copy of this [PlaceDetails] with optional updated values.
  PlaceDetails copyWith({
    String? placeId,
    String? name,
    String? nationalPhoneNumber,
    String? internationalPhoneNumber,
    String? formattedPhoneNumber,
    String? formattedAddress,
    String? streetAddress,
    String? streetNumber,
    String? city,
    String? state,
    String? region,
    String? zipCode,
    String? country,
    Location? location,
    String? googleMapsUri,
    String? websiteUri,
    String? website,
    double? rating,
    int? userRatingsTotal,
    Geometry? geometry,
  }) {
    return PlaceDetails(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      nationalPhoneNumber: nationalPhoneNumber ?? this.nationalPhoneNumber,
      internationalPhoneNumber:
          internationalPhoneNumber ?? this.internationalPhoneNumber,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      streetAddress: streetAddress ?? this.streetAddress,
      streetNumber: streetNumber ?? this.streetNumber,
      city: city ?? this.city,
      state: state ?? this.state,
      region: region ?? this.region,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      location: location ?? this.location,
      googleMapsUri: googleMapsUri ?? this.googleMapsUri,
      websiteUri: websiteUri ?? this.websiteUri,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      geometry: geometry ?? this.geometry,
    );
  }

  /// Converts this [PlaceDetails] to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'name': name,
      'nationalPhoneNumber': nationalPhoneNumber,
      'internationalPhoneNumber': internationalPhoneNumber,
      'formattedPhoneNumber': formattedPhoneNumber,
      'formattedAddress': formattedAddress,
      'streetAddress': streetAddress,
      'streetNumber': streetNumber,
      'city': city,
      'state': state,
      'region': region,
      'zipCode': zipCode,
      'country': country,
      'location': location?.toMap(),
      'googleMapsUri': googleMapsUri,
      'websiteUri': websiteUri,
      'website': website,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'geometry': geometry?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceDetails &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;

  @override
  String toString() =>
      'PlaceDetails(placeId: $placeId, name: $name, formattedAddress: $formattedAddress)';
}

/// Represents the geographical location coordinates of a place.
///
/// ## Example
/// ```dart
/// final location = details.location;
/// if (location != null) {
///   print('Coordinates: ${location.lat}, ${location.lng}');
/// }
/// ```
class Location {

  /// Constructor for creating a [Location] instance.
  const Location({
    required this.lat,
    required this.lng,
  });

  /// Creates a [Location] from a JSON map.
  factory Location.fromMap(Map<String, dynamic> json) {
    return Location(
      lat: (json['latitude'] ?? json['lat'] ?? 0.0) as double,
      lng: (json['longitude'] ?? json['lng'] ?? 0.0) as double,
    );
  }
  /// The latitude of the location.
  final double lat;

  /// The longitude of the location.
  final double lng;

  /// Converts this [Location] to a map.
  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'Location(lat: $lat, lng: $lng)';
}

/// Geometry information containing location coordinates.
///
/// This class wraps the [Location] for compatibility with different
/// response formats from the Places API.
class Geometry {

  /// Constructor for creating a [Geometry] instance.
  const Geometry({this.location});

  /// Creates a [Geometry] from a JSON map.
  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: json['location'] != null
          ? Location.fromMap(json['location'] as Map<String, dynamic>)
          : null,
    );
  }
  /// The location coordinates.
  final Location? location;

  /// Converts this [Geometry] to a map.
  Map<String, dynamic> toJson() {
    return {
      if (location != null) 'location': location!.toMap(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Geometry &&
          runtimeType == other.runtimeType &&
          location == other.location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'Geometry(location: $location)';
}
