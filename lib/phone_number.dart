import 'countries.dart';
import 'src/country_utils.dart';

class NumberTooLongException implements Exception {}

class NumberTooShortException implements Exception {}

class InvalidCharactersException implements Exception {}

class PhoneNumber {
  String countryISOCode;
  String countryCode;
  String number;

  PhoneNumber({required this.countryISOCode, required this.countryCode, required this.number});

  factory PhoneNumber.fromCompleteNumber({required String completeNumber}) {
    if (completeNumber == "") {
      return PhoneNumber(countryISOCode: "", countryCode: "", number: "");
    }

    try {
      Country country = getCountry(completeNumber);
      String number;
      if (completeNumber.startsWith('+')) {
        number = completeNumber.substring(1 + country.fullCountryCode.length);
      } else {
        number = completeNumber.substring(country.fullCountryCode.length);
      }
      return PhoneNumber(countryISOCode: country.code, countryCode: country.fullCountryCode, number: number);
    } on InvalidCharactersException {
      rethrow;
    } on Exception {
      return PhoneNumber(countryISOCode: "", countryCode: "", number: "");
    } on StateError {
      // No country matches the dial code.
      return PhoneNumber(countryISOCode: "", countryCode: "", number: "");
    }
  }

  bool isValidNumber() {
    Country country = _country();
    if (number.length < country.minLength) {
      throw NumberTooShortException();
    }

    if (number.length > country.maxLength) {
      throw NumberTooLongException();
    }
    return true;
  }

  String get completeNumber {
    return countryCode + number;
  }

  /// The country identified by [countryISOCode] when it agrees with
  /// [countryCode], otherwise the country derived from [completeNumber].
  Country _country() {
    final dialCode = countryCode.replaceFirst('+', '');
    for (final country in countries) {
      if (country.code == countryISOCode && country.fullCountryCode == dialCode) return country;
    }
    return getCountry(completeNumber);
  }

  /// Finds the country of an international [phoneNumber], with or without a
  /// leading `+`, by its longest matching dial code.
  ///
  /// Throws a [StateError] when no country matches.
  static Country getCountry(String phoneNumber) {
    if (phoneNumber == "") {
      throw NumberTooShortException();
    }

    final validPhoneNumber = RegExp(r'^\+?[0-9]*$');

    if (!validPhoneNumber.hasMatch(phoneNumber)) {
      throw InvalidCharactersException();
    }

    final digits = phoneNumber.startsWith('+') ? phoneNumber.substring(1) : phoneNumber;
    final country = matchCountryByPrefix(countries, digits);
    if (country == null) {
      throw StateError('No country found for $phoneNumber');
    }
    return country;
  }

  @override
  String toString() => 'PhoneNumber(countryISOCode: $countryISOCode, countryCode: $countryCode, number: $number)';
}
