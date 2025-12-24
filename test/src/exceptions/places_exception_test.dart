import 'package:flutter_test/flutter_test.dart';
import 'package:google_places_autocomplete/google_places_autocomplete.dart';

void main() {
  group('PlacesException', () {
    test('creates with message only', () {
      const exception = PlacesException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.details, isNull);
    });

    test('creates with all parameters', () {
      const exception = PlacesException(
        'Test error',
        code: 'TEST_CODE',
        details: {'extra': 'info'},
      );

      expect(exception.message, 'Test error');
      expect(exception.code, 'TEST_CODE');
      expect(exception.details, {'extra': 'info'});
    });

    test('toString includes code when present', () {
      const exception = PlacesException('Error', code: 'CODE');

      expect(exception.toString(), 'PlacesException(CODE): Error');
    });

    test('toString omits code when null', () {
      const exception = PlacesException('Error');

      expect(exception.toString(), 'PlacesException: Error');
    });
  });

  group('NotInitializedException', () {
    test('has default message', () {
      const exception = NotInitializedException();

      expect(exception.message, contains('not initialized'));
      expect(exception.code, 'NOT_INITIALIZED');
    });

    test('accepts custom message', () {
      const exception = NotInitializedException('Custom message');

      expect(exception.message, 'Custom message');
      expect(exception.code, 'NOT_INITIALIZED');
    });
  });

  group('ApiKeyException', () {
    test('has default message', () {
      const exception = ApiKeyException();

      expect(exception.message, contains('API key'));
      expect(exception.code, 'MISSING_API_KEY');
    });

    test('accepts custom message', () {
      const exception = ApiKeyException('Invalid key format');

      expect(exception.message, 'Invalid key format');
    });
  });

  group('PredictionException', () {
    test('creates with message', () {
      const exception = PredictionException('Request failed');

      expect(exception.message, 'Request failed');
      expect(exception.code, 'PREDICTION_ERROR');
    });

    test('accepts custom code', () {
      const exception = PredictionException(
        'Network error',
        code: 'NETWORK_ERROR',
      );

      expect(exception.code, 'NETWORK_ERROR');
    });
  });

  group('PlaceDetailsException', () {
    test('creates with message', () {
      const exception = PlaceDetailsException('Place not found');

      expect(exception.message, 'Place not found');
      expect(exception.code, 'PLACE_DETAILS_ERROR');
    });

    test('accepts details', () {
      const exception = PlaceDetailsException(
        'Error',
        details: 'Stack trace here',
      );

      expect(exception.details, 'Stack trace here');
    });
  });

  group('Exception hierarchy', () {
    test('NotInitializedException is PlacesException', () {
      const exception = NotInitializedException();

      expect(exception, isA<PlacesException>());
    });

    test('ApiKeyException is PlacesException', () {
      const exception = ApiKeyException();

      expect(exception, isA<PlacesException>());
    });

    test('PredictionException is PlacesException', () {
      const exception = PredictionException('test');

      expect(exception, isA<PlacesException>());
    });

    test('PlaceDetailsException is PlacesException', () {
      const exception = PlaceDetailsException('test');

      expect(exception, isA<PlacesException>());
    });
  });
}
