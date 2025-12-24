import 'package:flutter_test/flutter_test.dart';
import 'package:google_places_autocomplete/google_places_autocomplete.dart';

void main() {
  group('PlaceDetails', () {
    test('fromMap creates PlaceDetails with correct values', () {
      final map = {
        'placeId': 'test_place_id',
        'name': 'Test Restaurant',
        'formattedAddress': '123 Main St, City, State 12345',
        'rating': 4.5,
        'userRatingsTotal': 100,
        'location': {
          'lat': 37.7749,
          'lng': -122.4194,
        },
        'websiteUri': 'https://example.com',
        'phoneNumber': '+1-555-123-4567',
      };

      final details = PlaceDetails.fromMap(map);

      expect(details.placeId, 'test_place_id');
      expect(details.name, 'Test Restaurant');
      expect(details.formattedAddress, '123 Main St, City, State 12345');
      expect(details.rating, 4.5);
      expect(details.userRatingsTotal, 100);
      expect(details.location?.lat, 37.7749);
      expect(details.location?.lng, -122.4194);
      expect(details.websiteUri, 'https://example.com');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'placeId': 'test_id',
        'name': 'Simple Place',
      };

      final details = PlaceDetails.fromMap(map);

      expect(details.placeId, 'test_id');
      expect(details.name, 'Simple Place');
      expect(details.rating, isNull);
      expect(details.location, isNull);
      expect(details.websiteUri, isNull);
    });

    test('equality is based on placeId', () {
      const details1 = PlaceDetails(placeId: 'abc', name: 'Place 1');
      const details2 = PlaceDetails(placeId: 'abc', name: 'Place 2');
      const details3 = PlaceDetails(placeId: 'xyz', name: 'Place 1');

      expect(details1, equals(details2));
      expect(details1, isNot(equals(details3)));
    });

    test('toString includes key fields', () {
      const details = PlaceDetails(
        placeId: 'abc',
        name: 'Test',
        formattedAddress: '123 Street',
      );

      final str = details.toString();

      expect(str, contains('placeId: abc'));
      expect(str, contains('name: Test'));
      expect(str, contains('formattedAddress: 123 Street'));
    });

    test('toMap includes all fields', () {
      const details = PlaceDetails(
        placeId: 'abc',
        name: 'Test',
        formattedAddress: 'Address',
        rating: 4.0,
        location: Location(lat: 1.0, lng: 2.0),
      );

      final map = details.toMap();

      expect(map['placeId'], 'abc');
      expect(map['name'], 'Test');
      expect(map['formattedAddress'], 'Address');
      expect(map['rating'], 4.0);
      expect(map['location']['lat'], 1.0);
      expect(map['location']['lng'], 2.0);
    });

    test('copyWith creates new instance with updated values', () {
      const original = PlaceDetails(
        placeId: 'abc',
        name: 'Original',
        rating: 3.0,
      );

      final copied = original.copyWith(name: 'Updated', rating: 5.0);

      expect(copied.placeId, 'abc');
      expect(copied.name, 'Updated');
      expect(copied.rating, 5.0);
      expect(original.name, 'Original'); // Original unchanged
    });
  });

  group('Location', () {
    test('fromMap creates Location correctly', () {
      final json = {'lat': 37.7749, 'lng': -122.4194};

      final location = Location.fromMap(json);

      expect(location.lat, 37.7749);
      expect(location.lng, -122.4194);
    });

    test('fromMap handles latitude/longitude keys', () {
      final json = {'latitude': 37.7749, 'longitude': -122.4194};

      final location = Location.fromMap(json);

      expect(location.lat, 37.7749);
      expect(location.lng, -122.4194);
    });

    test('toMap produces correct map', () {
      const location = Location(lat: 37.7749, lng: -122.4194);

      final map = location.toMap();

      expect(map['lat'], 37.7749);
      expect(map['lng'], -122.4194);
    });

    test('equality works correctly', () {
      const l1 = Location(lat: 1.0, lng: 2.0);
      const l2 = Location(lat: 1.0, lng: 2.0);
      const l3 = Location(lat: 1.0, lng: 3.0);

      expect(l1, equals(l2));
      expect(l1, isNot(equals(l3)));
    });

    test('toString includes coordinates', () {
      const location = Location(lat: 37.7749, lng: -122.4194);

      expect(location.toString(), 'Location(lat: 37.7749, lng: -122.4194)');
    });
  });

  group('Geometry', () {
    test('fromJson creates Geometry correctly', () {
      final json = {
        'location': {'lat': 37.7749, 'lng': -122.4194},
      };

      final geometry = Geometry.fromJson(json);

      expect(geometry.location?.lat, 37.7749);
      expect(geometry.location?.lng, -122.4194);
    });

    test('fromJson handles null location', () {
      final json = <String, dynamic>{};

      final geometry = Geometry.fromJson(json);

      expect(geometry.location, isNull);
    });

    test('toJson produces correct map', () {
      const geometry = Geometry(
        location: Location(lat: 37.7749, lng: -122.4194),
      );

      final json = geometry.toJson();

      expect(json['location']['lat'], 37.7749);
      expect(json['location']['lng'], -122.4194);
    });
  });
}
