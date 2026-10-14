import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/src/country_utils.dart';

final RegExp _numeric = RegExp(r'^\+?\d+$');

/// Whether [s] is a non-empty string of digits, optionally starting with `+`.
bool isNumeric(String s) => _numeric.hasMatch(s);

const String _withDiacritics = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
const String _withoutDiacritics = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

final Map<int, int> _diacriticsMap = {
  for (var i = 0; i < _withDiacritics.length; i++) _withDiacritics.codeUnitAt(i): _withoutDiacritics.codeUnitAt(i),
};

/// Replaces common accented latin characters with their unaccented form.
String removeDiacritics(String str) {
  List<int>? codeUnits;
  for (var i = 0; i < str.length; i++) {
    final replacement = _diacriticsMap[str.codeUnitAt(i)];
    if (replacement != null) {
      (codeUnits ??= str.codeUnits.toList())[i] = replacement;
    }
  }
  return codeUnits == null ? str : String.fromCharCodes(codeUnits);
}

extension CountryExtensions on List<Country> {
  /// Countries whose name (in any language) contains [search], or whose dial
  /// code starts with [search] when it is numeric (`'44'`, `'+44'`).
  List<Country> stringSearch(String search) {
    final query = removeDiacritics(search.trim().toLowerCase());
    if (query.isEmpty) return toList();
    if (query.startsWith('+') || isNumeric(query)) {
      final digits = query.replaceAll('+', '');
      return where((country) => country.fullCountryCode.startsWith(digits)).toList();
    }
    return where((country) => countrySearchKeys(country).any((key) => key.contains(query))).toList();
  }
}
