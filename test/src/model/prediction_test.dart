import 'package:flutter_test/flutter_test.dart';
import 'package:google_places_autocomplete/google_places_autocomplete.dart';

void main() {
  group('Prediction', () {
    test('fromMap creates Prediction with correct values', () {
      final map = {
        'placeId': 'test_place_id',
        'distanceMeters': 1500,
        'structuredFormat': {
          'mainText': {'text': 'Test Place'},
          'secondaryText': {'text': '123 Test St, City'},
        },
      };

      final prediction = Prediction.fromMap(map);

      expect(prediction.placeId, 'test_place_id');
      expect(prediction.title, 'Test Place');
      expect(prediction.description, '123 Test St, City');
      expect(prediction.distanceMeters, 1500);
    });

    test('fromMap handles null distanceMeters', () {
      final map = {
        'placeId': 'test_place_id',
        'distanceMeters': null,
        'structuredFormat': {
          'mainText': {'text': 'Test Place'},
          'secondaryText': {'text': '123 Test St'},
        },
      };

      final prediction = Prediction.fromMap(map);

      expect(prediction.distanceMeters, isNull);
    });

    test('equality is based on placeId', () {
      const prediction1 = Prediction(placeId: 'abc', title: 'Place 1');
      const prediction2 = Prediction(placeId: 'abc', title: 'Place 2');
      const prediction3 = Prediction(placeId: 'xyz', title: 'Place 1');

      expect(prediction1, equals(prediction2));
      expect(prediction1, isNot(equals(prediction3)));
    });

    test('hashCode is based on placeId', () {
      const prediction1 = Prediction(placeId: 'abc');
      const prediction2 = Prediction(placeId: 'abc');

      expect(prediction1.hashCode, equals(prediction2.hashCode));
    });

    test('toString includes key fields', () {
      const prediction = Prediction(
        placeId: 'abc',
        title: 'Test',
        distanceMeters: 500,
      );

      final str = prediction.toString();

      expect(str, contains('placeId: abc'));
      expect(str, contains('title: Test'));
      expect(str, contains('distanceMeters: 500'));
    });

    test('toMap includes all fields', () {
      const prediction = Prediction(
        placeId: 'abc',
        title: 'Test',
        description: 'Description',
        distanceMeters: 500,
        types: ['restaurant'],
      );

      final map = prediction.toMap();

      expect(map['placeId'], 'abc');
      expect(map['title'], 'Test');
      expect(map['description'], 'Description');
      expect(map['distanceMeters'], 500);
      expect(map['types'], ['restaurant']);
    });

    test('copyWith creates new instance with updated values', () {
      const original = Prediction(
        placeId: 'abc',
        title: 'Original',
        distanceMeters: 100,
      );

      final copied = original.copyWith(title: 'Updated');

      expect(copied.placeId, 'abc');
      expect(copied.title, 'Updated');
      expect(copied.distanceMeters, 100);
      expect(original.title, 'Original'); // Original unchanged
    });
  });

  group('StructuredFormatting', () {
    test('fromJson creates instance correctly', () {
      final json = {
        'main_text': 'Main',
        'secondary_text': 'Secondary',
      };

      final formatting = StructuredFormatting.fromJson(json);

      expect(formatting.mainText, 'Main');
      expect(formatting.secondaryText, 'Secondary');
    });

    test('toJson produces correct map', () {
      const formatting = StructuredFormatting(
        mainText: 'Main',
        secondaryText: 'Secondary',
      );

      final json = formatting.toJson();

      expect(json['main_text'], 'Main');
      expect(json['secondary_text'], 'Secondary');
    });

    test('equality works correctly', () {
      const f1 = StructuredFormatting(mainText: 'A', secondaryText: 'B');
      const f2 = StructuredFormatting(mainText: 'A', secondaryText: 'B');
      const f3 = StructuredFormatting(mainText: 'A', secondaryText: 'C');

      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
    });
  });
}
