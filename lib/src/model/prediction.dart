/// Structured formatting for place predictions.
///
/// Contains the main and secondary text portions of a place prediction,
/// which can be used to display formatted search results.
///
/// ## Example
/// ```dart
/// final formatting = prediction.structuredFormatting;
/// print('Main: ${formatting?.mainText}');
/// print('Secondary: ${formatting?.secondaryText}');
/// ```
class StructuredFormatting {
  /// Constructs a [StructuredFormatting] object.
  const StructuredFormatting({
    this.mainText,
    this.secondaryText,
  });

  /// Creates a [StructuredFormatting] from a JSON map.
  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'] as String?,
      secondaryText: json['secondary_text'] as String?,
    );
  }

  /// The main text portion of the prediction's description.
  ///
  /// This is typically the name of the place (e.g., "Starbucks").
  final String? mainText;

  /// The secondary text portion of the prediction's description.
  ///
  /// This is typically the address or location details
  /// (e.g., "123 Main St, San Francisco, CA").
  final String? secondaryText;

  /// Converts this [StructuredFormatting] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'main_text': mainText,
      'secondary_text': secondaryText,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredFormatting &&
          runtimeType == other.runtimeType &&
          mainText == other.mainText &&
          secondaryText == other.secondaryText;

  @override
  int get hashCode => Object.hash(mainText, secondaryText);

  @override
  String toString() =>
      'StructuredFormatting(mainText: $mainText, secondaryText: $secondaryText)';
}

/// Represents a single prediction for an autocomplete query in Google Places API.
///
/// A prediction represents a potential match for a user's search query,
/// containing the place ID (for fetching details), display text, and
/// optionally distance from the user's location.
///
/// ## Example
/// ```dart
/// for (final prediction in predictions) {
///   print('${prediction.title} - ${prediction.distanceMeters}m away');
///
///   // Get full details when selected
///   if (prediction.placeId != null) {
///     final details = await places.getPlaceDetails(prediction.placeId!);
///   }
/// }
/// ```
class Prediction {
  /// Constructs a [Prediction] object.
  const Prediction({
    this.placeId,
    this.title,
    this.description,
    this.types,
    this.structuredFormatting,
    this.distanceMeters,
  });

  /// Creates a [Prediction] from a platform channel response map.
  ///
  /// The map should contain keys matching the native SDK response structure.
  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      placeId: map['placeId'] as String?,
      title: map['structuredFormat']?['mainText']?['text'] as String?,
      description:
          map['structuredFormat']?['secondaryText']?['text'] as String?,
      distanceMeters: map['distanceMeters'] as int?,
    );
  }

  /// The unique identifier of the place.
  ///
  /// Use this with [GooglePlacesAutocomplete.getPlaceDetails] to fetch
  /// full place information.
  final String? placeId;

  /// The title or main text of the place prediction.
  ///
  /// This is typically the name of the place (e.g., "Starbucks").
  final String? title;

  /// The description or secondary text of the place prediction.
  ///
  /// This usually contains address or location details.
  final String? description;

  /// The types of the place (e.g., `['restaurant', 'establishment']`).
  ///
  /// See the Google Places API documentation for a full list of place types.
  final List<String>? types;

  /// Structured formatting information for the place prediction.
  ///
  /// This provides the same information as [title] and [description]
  /// but in a structured format for more control over display.
  final StructuredFormatting? structuredFormatting;

  /// The distance in meters from the origin (user's location) to this place.
  ///
  /// This is only available when [GooglePlacesAutocomplete.originLat] and
  /// [GooglePlacesAutocomplete.originLng] are set. Returns `null` if no
  /// origin is provided.
  final int? distanceMeters;

  /// Creates a copy of this [Prediction] with optional updated values.
  ///
  /// Any value not provided will retain its current value.
  Prediction copyWith({
    String? placeId,
    String? title,
    String? description,
    List<String>? types,
    StructuredFormatting? structuredFormatting,
    int? distanceMeters,
  }) {
    return Prediction(
      placeId: placeId ?? this.placeId,
      title: title ?? this.title,
      description: description ?? this.description,
      types: types ?? this.types,
      structuredFormatting: structuredFormatting ?? this.structuredFormatting,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  /// Converts this [Prediction] to a map for serialization.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placeId': placeId,
      'title': title,
      'description': description,
      'types': types,
      'structuredFormatting': structuredFormatting?.toJson(),
      'distanceMeters': distanceMeters,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prediction &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;

  @override
  String toString() =>
      'Prediction(placeId: $placeId, title: $title, distanceMeters: $distanceMeters)';
}
