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

    test('full name accepts normal names and rejects numeric names', () {
      expect(Validators.fullName("Meemona Chohan"), isNull);
      expect(Validators.fullName('Meemona123'), isNotNull);
      expect(Validators.fullName('-123'), isNotNull);
    });

    test('email accepts a normal address', () {
      expect(Validators.email('applicant@example.com'), isNull);
    });

    test('Pakistani phone accepts 03XX formatting and rejects invalid numbers', () {
      expect(Validators.phone('0306-2480041'), isNull);
      expect(Validators.phone('1306-2480041'), isNotNull);
      expect(Validators.phone('0306-248004'), isNotNull);
    });

    test('company name requires meaningful letters', () {
      expect(Validators.companyName('Skyline Associates'), isNull);
      expect(Validators.companyName('12345'), isNotNull);
      expect(Validators.companyName('@@@'), isNotNull);
    });

    test('NTN accepts valid numeric format and rejects letters or negatives', () {
      expect(Validators.ntn('1234567'), isNull);
      expect(Validators.ntn('1234567-8'), isNull);
      expect(Validators.ntn('jhg'), isNotNull);
      expect(Validators.ntn('-1234567'), isNotNull);
    });

    test('address and area require meaningful text', () {
      expect(Validators.address('Office 12, Block A'), isNull);
      expect(Validators.address('1234'), isNotNull);
      expect(Validators.area('Model Town'), isNull);
      expect(Validators.area('123'), isNotNull);
    });

    test('non-negative number rejects negative and invalid numbers', () {
      expect(Validators.nonNegativeNumber('0', 'Amount'), isNull);
      expect(Validators.nonNegativeNumber('2500', 'Amount'), isNull);
      expect(Validators.nonNegativeNumber('-1', 'Amount'), isNotNull);
      expect(Validators.nonNegativeNumber('abc', 'Amount'), isNotNull);
    });

    test('password requires uppercase and a number', () {
      expect(Validators.password('Password1'), isNull);
      expect(Validators.password('password'), isNotNull);
    });
  });
}
