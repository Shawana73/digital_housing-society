import 'package:flutter_test/flutter_test.dart';
import 'package:digital_housing_society/utils/formatters_validators.dart';

void main() {
  group('DHS validators', () {
    test('CNIC accepts 13 digits with formatting', () {
      expect(Validators.cnic('35202-1234567-8'), isNull);
    });

    test('CNIC rejects wrong length', () {
      expect(Validators.cnic('35202-123'), isNotNull);
    });

    test('email accepts a normal address', () {
      expect(Validators.email('applicant@example.com'), isNull);
    });

    test('password requires uppercase and a number', () {
      expect(Validators.password('Password1'), isNull);
      expect(Validators.password('password'), isNotNull);
    });
  });
}
