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
///   print('City: ${details.city}');
///   print('Address Components: ${details.addressComponents?.length}');
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
    this.addressComponents,
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
    this.businessStatus,
    this.types,
    this.utcOffset,
    this.plusCode,
    this.viewport,
  });

  /// Creates a [PlaceDetails] from a platform channel response map.
  factory PlaceDetails.fromMap(Map<dynamic, dynamic> map) {
    // Safely extract address components list
    final rawAddressComponents = map['addressComponents'];
    List<AddressComponent>? addressComponents;
    if (rawAddressComponents is List) {
      addressComponents = rawAddressComponents
          .whereType<Map>()
          .map((c) => AddressComponent.fromMap(Map<String, dynamic>.from(c)))
          .toList();
    }

    String? extractAddressComponent(String type) {
      if (addressComponents == null) return null;
      for (final component in addressComponents) {
        if (component.types.contains(type)) {
          return component.longText;
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

    // Safely extract plus code
    PlusCode? plusCode;
    final rawPlusCode = map['plusCode'];
    if (rawPlusCode != null && rawPlusCode is Map) {
      plusCode = PlusCode.fromMap(Map<String, dynamic>.from(rawPlusCode));
    }

    // Safely extract viewport
    Viewport? viewport;
    final rawViewport = map['viewport'];
    if (rawViewport != null && rawViewport is Map) {
      viewport = Viewport.fromMap(Map<String, dynamic>.from(rawViewport));
    }

    // Extract types list
    List<String>? types;
    final rawTypes = map['types'];
    if (rawTypes is List) {
      types = rawTypes.whereType<String>().toList();
    }

    return PlaceDetails(
      placeId: map['placeId'] as String?,
      name: map['name'] as String?,
      nationalPhoneNumber: map['nationalPhoneNumber'] as String?,
      internationalPhoneNumber: map['internationalPhoneNumber'] as String?,
      formattedPhoneNumber: map['formattedPhoneNumber'] as String?,
      formattedAddress: map['formattedAddress'] as String?,
      addressComponents: addressComponents,
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
      businessStatus: map['businessStatus'] as String?,
      types: types,
      utcOffset: map['utcOffset'] as int?,
      plusCode: plusCode,
      viewport: viewport,
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

  /// The raw address components list from the API.
  final List<AddressComponent>? addressComponents;

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

  /// The business status of the place (e.g., OPERATIONAL, CLOSED_TEMPORARILY).
  final String? businessStatus;

  /// The place types (e.g., restaurant, cafe, etc.).
  final List<String>? types;

  /// The UTC offset in minutes from UTC.
  final int? utcOffset;

  /// The Plus Code for the place location.
  final PlusCode? plusCode;

  /// The viewport for displaying this place on a map.
  final Viewport? viewport;

  /// Creates a copy of this [PlaceDetails] with optional updated values.
  PlaceDetails copyWith({
    String? placeId,
    String? name,
    String? nationalPhoneNumber,
    String? internationalPhoneNumber,
    String? formattedPhoneNumber,
    String? formattedAddress,
    List<AddressComponent>? addressComponents,
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
    String? businessStatus,
    List<String>? types,
    int? utcOffset,
    PlusCode? plusCode,
    Viewport? viewport,
  }) {
    return PlaceDetails(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      nationalPhoneNumber: nationalPhoneNumber ?? this.nationalPhoneNumber,
      internationalPhoneNumber:
          internationalPhoneNumber ?? this.internationalPhoneNumber,
      formattedPhoneNumber: formattedPhoneNumber ?? this.formattedPhoneNumber,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      addressComponents: addressComponents ?? this.addressComponents,
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
      businessStatus: businessStatus ?? this.businessStatus,
      types: types ?? this.types,
      utcOffset: utcOffset ?? this.utcOffset,
      plusCode: plusCode ?? this.plusCode,
      viewport: viewport ?? this.viewport,
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
      'addressComponents': addressComponents?.map((c) => c.toMap()).toList(),
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
      'businessStatus': businessStatus,
      'types': types,
      'utcOffset': utcOffset,
      'plusCode': plusCode?.toMap(),
      'viewport': viewport?.toMap(),
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

/// Represents an individual address component from the Places API.
///
/// Each component has a long and short form of the text, along with
/// the types indicating what kind of component it is.
///
/// ## Example
/// ```dart
/// for (final component in details.addressComponents ?? []) {
///   if (component.types.contains('locality')) {
///     print('City: ${component.longText}');
///   }
/// }
/// ```
class AddressComponent {
  /// Constructor for creating an [AddressComponent] instance.
  const AddressComponent({
    required this.longText,
    this.shortText,
    required this.types,
  });

  /// Creates an [AddressComponent] from a JSON map.
  factory AddressComponent.fromMap(Map<String, dynamic> map) {
    final rawTypes = map['types'];
    List<String> types = [];
    if (rawTypes is List) {
      types = rawTypes.whereType<String>().toList();
    }
    return AddressComponent(
      longText: map['longText'] as String? ?? '',
      shortText: map['shortText'] as String?,
      types: types,
    );
  }

  /// The full text of the component (e.g., "California").
  final String longText;

  /// The abbreviated text of the component (e.g., "CA").
  final String? shortText;

  /// The types of this component (e.g., ["administrative_area_level_1"]).
  final List<String> types;

  /// Converts this [AddressComponent] to a map.
  Map<String, dynamic> toMap() {
    return {
      'longText': longText,
      'shortText': shortText,
      'types': types,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressComponent &&
          runtimeType == other.runtimeType &&
          longText == other.longText &&
          shortText == other.shortText;

  @override
  int get hashCode => Object.hash(longText, shortText);

  @override
  String toString() =>
      'AddressComponent(longText: $longText, shortText: $shortText, types: $types)';
}

/// Represents a Plus Code for a location.
///
/// Plus Codes are short, unique identifiers for locations.
class PlusCode {
  /// Constructor for creating a [PlusCode] instance.
  const PlusCode({
    this.globalCode,
    this.compoundCode,
  });

  /// Creates a [PlusCode] from a JSON map.
  factory PlusCode.fromMap(Map<String, dynamic> map) {
    return PlusCode(
      globalCode: map['globalCode'] as String?,
      compoundCode: map['compoundCode'] as String?,
    );
  }

  /// The global Plus Code (e.g., "8FVC9G8F+5W").
  final String? globalCode;

  /// The compound Plus Code with locality (e.g., "9G8F+5W Zurich, Switzerland").
  final String? compoundCode;

  /// Converts this [PlusCode] to a map.
  Map<String, dynamic> toMap() {
    return {
      'globalCode': globalCode,
      'compoundCode': compoundCode,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlusCode &&
          runtimeType == other.runtimeType &&
          globalCode == other.globalCode &&
          compoundCode == other.compoundCode;

  @override
  int get hashCode => Object.hash(globalCode, compoundCode);

  @override
  String toString() =>
      'PlusCode(globalCode: $globalCode, compoundCode: $compoundCode)';
}

/// Represents a viewport for displaying a place on a map.
class Viewport {
  /// Constructor for creating a [Viewport] instance.
  const Viewport({
    this.northeast,
    this.southwest,
  });

  /// Creates a [Viewport] from a JSON map.
  factory Viewport.fromMap(Map<String, dynamic> map) {
    Location? northeast;
    Location? southwest;

    final rawNortheast = map['northeast'];
    if (rawNortheast is Map) {
      northeast = Location.fromMap(Map<String, dynamic>.from(rawNortheast));
    }

    final rawSouthwest = map['southwest'];
    if (rawSouthwest is Map) {
      southwest = Location.fromMap(Map<String, dynamic>.from(rawSouthwest));
    }

    return Viewport(
      northeast: northeast,
      southwest: southwest,
    );
  }

  /// The northeast corner of the viewport.
  final Location? northeast;

  /// The southwest corner of the viewport.
  final Location? southwest;

  /// Converts this [Viewport] to a map.
  Map<String, dynamic> toMap() {
    return {
      'northeast': northeast?.toMap(),
      'southwest': southwest?.toMap(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Viewport &&
          runtimeType == other.runtimeType &&
          northeast == other.northeast &&
          southwest == other.southwest;

  @override
  int get hashCode => Object.hash(northeast, southwest);

  @override
  String toString() => 'Viewport(northeast: $northeast, southwest: $southwest)';
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
