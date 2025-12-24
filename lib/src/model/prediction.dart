/// Structured formatting for place predictions.
class StructuredFormatting {
  /// The main text portion of the prediction's description
  final String? mainText;

  /// The secondary text portion of the prediction's description
  final String? secondaryText;

  /// Constructs a [StructuredFormatting] object.
  StructuredFormatting({
    this.mainText,
    this.secondaryText,
  });

  /// Creates a [StructuredFormatting] from a JSON map
  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'] as String?,
      secondaryText: json['secondary_text'] as String?,
    );
  }
}

/// Represents a single prediction for an autocomplete query in Google Places API.
class Prediction {
  /// The unique identifier of the place.
  final String? placeId;

  /// The title or main text of the place prediction.
  final String? title;

  /// The description or secondary text of the place prediction.
  final String? description;

  /// The types of the place (e.g., restaurant, establishment)
  final List<String>? types;

  /// Structured formatting information for the place prediction
  final StructuredFormatting? structuredFormatting;

  /// The distance in meters from the origin (user's location) to this place.
  /// Only available when origin is provided in the autocomplete request.
  final int? distanceMeters;

  /// Constructs a [Prediction] object.
  ///
  /// All parameters are optional.
  Prediction({
    this.placeId,
    this.title,
    this.description,
    this.types,
    this.structuredFormatting,
    this.distanceMeters,
  });

  /// Creates a copy of the current [Prediction] instance with optional updated values.
  ///
  /// If a value is not provided, the existing value is retained.
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

  /// Converts the [Prediction] instance to a map for serialization.
  ///
  /// Returns a map representation of the object, where the keys are the field names.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placeId': placeId,
      'title': title,
      'description': description,
      'distanceMeters': distanceMeters,
    };
  }

  /// Factory method to create a [Prediction] instance from a map.
  ///
  /// The map should contain keys matching the expected structure, such as
  /// `placeId`, `structuredFormat.mainText.text`, and `structuredFormat.secondaryText.text`.
  factory Prediction.fromMap(Map<String, dynamic> map) {
    return Prediction(
      placeId: map['placeId'],
      title: map['structuredFormat']?['mainText']?['text'],
      description: map['structuredFormat']?['secondaryText']?['text'],
      distanceMeters: map['distanceMeters'] as int?,
    );
  }
}
