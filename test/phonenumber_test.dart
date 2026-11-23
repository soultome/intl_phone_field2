// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

//import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/helpers.dart';
import 'package:intl_phone_field2/src/country_utils.dart';
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
      expect(PhoneNumber.getCountry('+13455551234').code, 'KY');
      expect(PhoneNumber.getCountry('+34555123456').code, 'ES');
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

  group('parsePhoneNumberInput', () {
    Country country(String code) => countries.firstWhere((c) => c.code == code);

    ({String code, String number})? parse(String text, {String selected = 'US', List<Country>? from}) {
      final parsed = parsePhoneNumberInput(
        countries: from ?? countries,
        selectedCountry: country(selected),
        text: text,
      );
      return parsed == null ? null : (code: parsed.country.code, number: parsed.number);
    }

    test('reads the country from an international number', () {
      expect(parse('+977 984-123 4567'), (code: 'NP', number: '9841234567'));
      expect(parse('+44 1481 960194', selected: 'GB'), (code: 'GG', number: '960194'));
    });

    test('prefers the selected country among those sharing a dial code', () {
      expect(parse('+1 416 555 0123', selected: 'CA'), (code: 'CA', number: '4165550123'));
      expect(parse('+1 416 555 0123', selected: 'NP'), (code: 'US', number: '4165550123'));
    });

    test('removes separators and invisible marks', () {
      final ltrOverride = String.fromCharCode(0x202D);
      final popFormatting = String.fromCharCode(0x202C);
      expect(parse('$ltrOverride+44 7911 123456$popFormatting'), (code: 'GB', number: '7911123456'));
      expect(parse('(202) 555-0123'), (code: 'US', number: '2025550123'));
      expect(parse('202.555.0123'), (code: 'US', number: '2025550123'));
    });

    test('removes the selected country code only from a number too long without it', () {
      expect(parse('12025550123'), (code: 'US', number: '2025550123'));
      expect(parse('9123456789', selected: 'IN'), (code: 'IN', number: '9123456789'));
    });

    test('an international number replaces digits before it', () {
      expect(parse('98+977 9841234567'), (code: 'NP', number: '9841234567'));
    });

    test('keeps the selected country and the dial code when that country is not available', () {
      final available = [country('NP'), country('IN')];
      expect(parse('+1 202 555 0123', selected: 'NP', from: available), (code: 'NP', number: '+12025550123'));
    });

    test('returns null for text that is not a phone number', () {
      expect(parse(''), isNull);
      expect(parse('+'), isNull);
      expect(parse('call me'), isNull);
      expect(parse('555*1234'), isNull);
      expect(parse(',123'), isNull);
    });

    test('reads the 00 international prefix', () {
      expect(parse('0044 7911 123456'), (code: 'GB', number: '7911123456'));
      expect(parse('00977 9841234567', selected: 'NP'), (code: 'NP', number: '9841234567'));
      final available = [country('NP')];
      expect(parse('0044 7911 123456', selected: 'NP', from: available), (code: 'NP', number: '+447911123456'));
    });

    test('removes a trunk prefix only when the number is too long with it', () {
      expect(parse('+44 (0)7911 123456'), (code: 'GB', number: '7911123456'));
      expect(parse('+44 07911 123456'), (code: 'GB', number: '7911123456'));
      expect(parse('07911 123456', selected: 'GB'), (code: 'GB', number: '7911123456'));
      // These countries keep the leading 0 in international numbers.
      expect(parse('+39 06 1234 5678'), (code: 'IT', number: '0612345678'));
      expect(parse('+225 07 01 23 45 67'), (code: 'CI', number: '0701234567'));
    });

    test('drops an extension after a pause or wait', () {
      expect(parse('+1 (202) 555-0123,45'), (code: 'US', number: '2025550123'));
      expect(parse('+1 (202) 555-0123;45'), (code: 'US', number: '2025550123'));
    });

    test('reads digits of other scripts', () {
      String inScript(String text, int zero) =>
          String.fromCharCodes(text.codeUnits.map((u) => u >= 0x30 && u <= 0x39 ? u - 0x30 + zero : u));
      expect(parse(inScript('+977 9841234567', 0x0660)), (code: 'NP', number: '9841234567')); // Arabic-Indic
      expect(parse(inScript('+977 9841234567', 0x06F0)), (code: 'NP', number: '9841234567')); // Persian
      expect(parse(inScript('+977 9841234567', 0x0966)), (code: 'NP', number: '9841234567')); // Devanagari
      final fullWidth = String.fromCharCode(0xFF0B) + inScript('44 7911 123456', 0xFF10);
      expect(parse(fullWidth), (code: 'GB', number: '7911123456'));
    });

    test('maps the cursor to the same digits', () {
      int cursorOf(String text, int cursor) => parsePhoneNumberInput(
        countries: countries,
        selectedCountry: country('US'),
        text: text,
        cursor: cursor,
      )!.cursor;
      expect(cursorOf('202555-0123', 7), 6);
      expect(cursorOf('(202) 555', 5), 3);
      expect(cursorOf('+1 202 555 0123', 15), 10);
      expect(cursorOf('+1 202 555 0123', 0), 0);
    });

    test('every country is read back from its international number', () {
      for (final c in countries) {
        final national = '5' * c.minLength;
        final parsed = parse('+${c.fullCountryCode} $national', selected: c.code);
        expect(parsed, (code: c.code, number: national), reason: c.name);
      }
    });

    test('random input never throws and returns only digits and +', () {
      final random = Random(7);
      const pieces = ['0', '1', '4', '7', '9', '00', '+', ' ', '-', '(', ')', '(0)', '.', ',', ';', 'x', '*', '#'];
      final extra = [0x202D, 0x202C, 0x00A0, 0x0661, 0x0967, 0xFF0B, 0xFF15].map(String.fromCharCode);
      final alphabet = [...pieces, ...extra];
      for (var i = 0; i < 20000; i++) {
        final text = List.generate(random.nextInt(24), (_) => alphabet[random.nextInt(alphabet.length)]).join();
        final selected = countries[random.nextInt(countries.length)];
        final cursor = text.isEmpty ? 0 : random.nextInt(text.length + 1);
        final parsed = parsePhoneNumberInput(
          countries: countries,
          selectedCountry: selected,
          text: text,
          cursor: cursor,
        );
        if (parsed == null) continue;
        expect(parsed.number, matches(RegExp(r'^\+?\d*$')), reason: text);
        expect(parsed.cursor, inInclusiveRange(0, parsed.number.length), reason: text);
      }
    });
  });
}
