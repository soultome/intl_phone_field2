// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

//import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/helpers.dart';
import 'package:test/test.dart';
import 'package:intl_phone_field2/phone_number.dart';

void main() {
  group('PhoneNumber', () {
    test('create a phone number', () {
      PhoneNumber phoneNumber = PhoneNumber(countryISOCode: "UK", countryCode: "+44", number: "7891234567");
      String actual = phoneNumber.completeNumber;
      String expected = "+447891234567";

      expect(actual, expected);
      expect(phoneNumber.isValidNumber(), true);
    });

    test('create a Guernsey number', () {
      PhoneNumber phoneNumber = PhoneNumber(countryISOCode: "GG", countryCode: "+441481", number: "960194");
      String actual = phoneNumber.completeNumber;
      String expected = "+441481960194";

      expect(actual, expected);
      expect(phoneNumber.isValidNumber(), true);
    });

    test('look up UK as a country code', () {
      Country country = PhoneNumber.getCountry("+447891234567");
      expect(country.name, "United Kingdom");
      expect(country.code, "GB");
      expect(country.regionCode, "");
    });

    test('look up Guernsey as a country code', () {
      Country country = PhoneNumber.getCountry("+441481960194");
      expect(country.name, "Guernsey");
      expect(country.code, "GG");
      expect(country.regionCode, "1481");
    });

    test('create with empty complete number', () {
      PhoneNumber phoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: "");
      expect(phoneNumber.countryISOCode, "");
      expect(phoneNumber.countryCode, "");
      expect(phoneNumber.number, "");
      expect(() => phoneNumber.isValidNumber(), throwsA(const TypeMatcher<NumberTooShortException>()));
    });

    test('create HK  number +85212345678', () {
      PhoneNumber phoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: "+85212345678");
      expect(phoneNumber.countryISOCode, "HK");
      expect(phoneNumber.countryCode, "852");
      expect(phoneNumber.number, "12345678");
      expect(phoneNumber.isValidNumber(), true);
    });

    test('Number is too short number +8521234567', () {
      PhoneNumber ph = PhoneNumber.fromCompleteNumber(completeNumber: "+8521234567");
      expect(() => ph.isValidNumber(), throwsA(const TypeMatcher<NumberTooShortException>()));
    });

    test('cannot create from too long number +852123456789', () {
      PhoneNumber ph = PhoneNumber.fromCompleteNumber(completeNumber: "+852123456789");

      expect(() => ph.isValidNumber(), throwsA(const TypeMatcher<NumberTooLongException>()));
    });

    test('create UK PhoneNumber from +447891234567', () {
      PhoneNumber phoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: "+447891234567");
      expect(phoneNumber.countryISOCode, "GB");
      expect(phoneNumber.countryCode, "44");
      expect(phoneNumber.number, "7891234567");
      expect(phoneNumber.isValidNumber(), true);
    });

    test('create Guernsey PhoneNumber from +441481960194', () {
      PhoneNumber phoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: "+441481960194");
      expect(phoneNumber.countryISOCode, "GG");
      expect(phoneNumber.countryCode, "441481");
      expect(phoneNumber.number, "960194");
      expect(phoneNumber.isValidNumber(), true);
    });

    test('create alpha character in  PhoneNumber from +44abcdef', () {
      expect(
        () => PhoneNumber.fromCompleteNumber(completeNumber: "+44abcdef"),
        throwsA(const TypeMatcher<InvalidCharactersException>()),
      );
    });

    test('create alpha character in  PhoneNumber from +44abcdef1', () {
      expect(
        () => PhoneNumber.fromCompleteNumber(completeNumber: "+44abcdef1"),
        throwsA(const TypeMatcher<InvalidCharactersException>()),
      );
    });
  });

  group('dial code lookup', () {
    test('prefers the longest dial code', () {
      expect(PhoneNumber.getCountry('+18765551234').code, 'JM');
      expect(PhoneNumber.getCountry('+12125551234').code, 'US');
      expect(PhoneNumber.getCountry('+34912345678').code, 'ES');
    });

    test('unknown dial code gives an empty number instead of throwing', () {
      final phoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: '+999123456');
      expect(phoneNumber.countryISOCode, '');
      expect(() => PhoneNumber.getCountry('+999123456'), throwsStateError);
    });

    test('isValidNumber uses the ISO code to tell apart countries sharing a dial code', () {
      final kazakh = PhoneNumber(countryISOCode: 'KZ', countryCode: '+7', number: '7011234567');
      expect(kazakh.isValidNumber(), true);
    });
  });

  group('helpers', () {
    test('removeDiacritics', () {
      expect(removeDiacritics('Åland Islands'), 'Aland Islands');
      expect(removeDiacritics('Côte d\'Ivoire'), 'Cote d\'Ivoire');
      expect(removeDiacritics('plain'), 'plain');
    });

    test('isNumeric', () {
      expect(isNumeric('123'), true);
      expect(isNumeric('+44'), true);
      expect(isNumeric(''), false);
      expect(isNumeric('12a'), false);
      expect(isNumeric(' 12 '), false);
    });

    test('stringSearch matches names in any language and dial codes', () {
      expect(countries.stringSearch('deutschland').map((c) => c.code), ['DE']);
      expect(countries.stringSearch('+44').map((c) => c.code), containsAll(['GB', 'GG', 'IM', 'JE']));
      expect(countries.stringSearch('+441481').map((c) => c.code), ['GG']);
    });
  });
}
