import '../countries.dart';
import '../helpers.dart';

/// The country picked when several countries share the same dial code and
/// nothing else (an explicit country code) disambiguates them.
const Map<String, String> _primaryCountryForDialCode = {
  '1': 'US',
  '7': 'RU',
  '44': 'GB',
  '47': 'NO',
  '61': 'AU',
  '64': 'NZ',
  '262': 'RE',
  '358': 'FI',
  '500': 'FK',
  '590': 'GP',
  '672': 'NF',
};

final RegExp _nonDigits = RegExp(r'\D');
final RegExp _digitsOnly = RegExp(r'^\d+$');
final RegExp _leadingSeparators = RegExp(r'^[\s\-.()]+');

/// Separators and invisible formatting characters in numbers copied from
/// contacts, such as `+1 (555) 123-4567`, including the bidi marks iOS can wrap
/// around them.
final RegExp _phoneFormatting = RegExp(r'[\s\-.()/\u00AD\u2010-\u2015\u2212\u200B-\u200F\u202A-\u202E\u2060-\u2064]');
final RegExp _phoneNumberInput = RegExp(r'^\+?\d+$');

/// iOS and Android contacts store an extension after a pause (`,`) or a wait
/// (`;`).
final RegExp _phonePause = RegExp('[,;]');

/// An optional trunk prefix, as in `+44 (0)7911 123456`.
final RegExp _trunkPrefixNotation = RegExp(r'\(\s*0\s*\)');

/// The zero of each digit set a phone number may be written in: Arabic-Indic,
/// Persian, Devanagari, Bengali, Thai and full-width.
const List<int> _unicodeZeros = [0x0660, 0x06F0, 0x0966, 0x09E6, 0x0E50, 0xFF10];
const int _fullWidthPlus = 0xFF0B;

bool isSameCountry(Country a, Country b) => a.code == b.code && a.fullCountryCode == b.fullCountryCode;

/// Finds a country by ISO 3166 alpha-2 code (`'IN'`, case-insensitive) or by
/// dial code (`'+225'`, `'225'`).
Country? findCountry(List<Country> countries, String code) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return null;

  final dialCode = (trimmed.startsWith('+') ? trimmed.substring(1) : trimmed).replaceAll(RegExp(r'[\s-]'), '');
  if (_digitsOnly.hasMatch(dialCode)) {
    final exact = countries.where((c) => c.fullCountryCode == dialCode).toList();
    if (exact.isNotEmpty) return _pickPrimary(exact, dialCode);
    final byDialCode = countries.where((c) => c.dialCode == dialCode).toList();
    if (byDialCode.isNotEmpty) return _pickPrimary(byDialCode, dialCode);
    return null;
  }

  final upper = trimmed.toUpperCase();
  for (final country in countries) {
    if (country.code == upper) return country;
  }
  return null;
}

/// Returns the country whose full dial code (dial code + region code) is the
/// longest prefix of [digits].
///
/// When several countries share that prefix, [preferredIsoCode] wins, then the
/// primary country of the dial code (for example `US` for `+1`).
Country? matchCountryByPrefix(List<Country> countries, String digits, {String? preferredIsoCode}) {
  var bestLength = 0;
  final candidates = <Country>[];
  for (final country in countries) {
    final prefix = country.fullCountryCode;
    if (prefix.isEmpty || prefix.length < bestLength || !digits.startsWith(prefix)) continue;
    if (prefix.length > bestLength) {
      bestLength = prefix.length;
      candidates.clear();
    }
    candidates.add(country);
  }
  if (candidates.isEmpty) return null;
  if (preferredIsoCode != null) {
    final preferred = preferredIsoCode.toUpperCase();
    for (final country in candidates) {
      if (country.code == preferred) return country;
    }
  }
  return _pickPrimary(candidates, candidates.first.fullCountryCode);
}

Country _pickPrimary(List<Country> candidates, String dialCode) {
  if (candidates.length > 1) {
    final primary = _primaryCountryForDialCode[dialCode];
    for (final country in candidates) {
      if (country.code == primary) return country;
    }
  }
  return candidates.first;
}

/// Splits an initial value such as `+447891234567` into its country and
/// national number.
({Country country, String number}) parseInitialPhoneNumber({
  required List<Country> countries,
  required String? initialCountryCode,
  required String? initialValue,
}) {
  assert(countries.isNotEmpty, 'The countries list must not be empty');
  final explicitCountry = initialCountryCode == null ? null : findCountry(countries, initialCountryCode);
  var country = explicitCountry ?? findCountry(countries, 'US') ?? countries.first;
  var number = (initialValue ?? '').trim();

  if (number.startsWith('+')) {
    // A full international number names its own country; an explicit
    // initialCountryCode only breaks ties between countries sharing a prefix.
    final international = number.substring(1);
    final digits = international.replaceAll(_nonDigits, '');
    country = matchCountryByPrefix(countries, digits, preferredIsoCode: explicitCountry?.code) ?? country;
    number = _stripPrefix(international, country.fullCountryCode);
  } else if (number.length > country.maxLength && number.startsWith(country.fullCountryCode)) {
    // Only treat leading digits as the country code when the value is too long
    // to be a national number on its own, so `9123456789` (India) stays intact.
    number = number.substring(country.fullCountryCode.length);
  }

  return (country: country, number: number.replaceFirst(_leadingSeparators, ''));
}

/// Reads a phone number entered all at once, such as an autofilled
/// `+977 984-1234567`, into its country and national number, without
/// separators, extension or trunk prefix.
///
/// An international number, with `+` or `00`, selects the country of its dial
/// code, preferring [selectedCountry] among countries that share it. When no
/// country in [countries] has that dial code, [selectedCountry] is kept along
/// with the `+` and dial code, so the number fails validation instead of
/// passing for a national number.
///
/// [cursor] is an offset in [text]; the returned `cursor` is the matching
/// offset in the number, or its end when [cursor] is null.
///
/// Returns `null` when [text] is not a phone number.
({Country country, String number, int cursor})? parsePhoneNumberInput({
  required List<Country> countries,
  required Country selectedCountry,
  required String text,
  int? cursor,
}) {
  final characters = _phoneNumberCharacters(text);
  final parsed = _readPhoneNumber(countries, selectedCountry, characters);
  if (parsed == null) return null;

  // Apart from separators, characters are only removed before the national
  // number, so the cursor keeps the same digits after it.
  final length = parsed.number.length;
  var offset = length;
  if (cursor != null && cursor >= 0 && cursor < text.length) {
    final after = characters.length - _phoneNumberCharacters(text.substring(0, cursor)).length;
    offset = (length - after).clamp(0, length);
  }
  return (country: parsed.country, number: parsed.number, cursor: offset);
}

({Country country, String number})? _readPhoneNumber(List<Country> countries, Country selected, String characters) {
  var number = characters;
  // An international number entered after other digits replaces them.
  final plus = number.lastIndexOf('+');
  if (plus > 0) number = number.substring(plus);
  if (!_phoneNumberInput.hasMatch(number)) return null;

  if (number.startsWith('+')) {
    return _readInternational(countries, selected, number.substring(1)) ?? (country: selected, number: number);
  }

  // 00 is the international prefix in most countries, as in 0044 7911 123456.
  if (number.startsWith('00') && number.length > selected.maxLength) {
    final digits = number.substring(2);
    final international = _readInternational(countries, selected, digits);
    if (international != null) return international;
    if (matchCountryByPrefix(_allCountries, digits) != null) return (country: selected, number: '+$digits');
  }

  // As for an initialValue, leading digits are only the country code when the
  // number is too long without them.
  final dialCode = selected.fullCountryCode;
  if (number.length > selected.maxLength && number.startsWith(dialCode)) {
    number = number.substring(dialCode.length);
  }
  return (country: selected, number: _withoutTrunkPrefix(number, selected));
}

({Country country, String number})? _readInternational(List<Country> countries, Country selected, String digits) {
  final country = matchCountryByPrefix(countries, digits, preferredIsoCode: selected.code);
  if (country == null) return null;
  return (country: country, number: _withoutTrunkPrefix(digits.substring(country.fullCountryCode.length), country));
}

/// Removes the trunk prefix of numbers such as `07911 123456` or
/// `+44 07911 123456`. Numbers that fit the country's length keep their
/// leading 0, which is part of the number in countries such as Italy.
String _withoutTrunkPrefix(String number, Country country) =>
    number.length > country.maxLength && number.startsWith('0') ? number.substring(1) : number;

/// The characters of [text] that make up a phone number: ASCII digits and `+`,
/// without separators, a trunk prefix in parentheses or an extension.
String _phoneNumberCharacters(String text) {
  final pause = text.indexOf(_phonePause);
  final number = pause < 0 ? text : text.substring(0, pause);
  return _asciiDigits(number).replaceAll(_trunkPrefixNotation, '').replaceAll(_phoneFormatting, '');
}

String _asciiDigits(String text) {
  List<int>? codeUnits;
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit < _unicodeZeros.first) continue;
    int? ascii;
    if (unit == _fullWidthPlus) {
      ascii = 0x2B;
    } else {
      for (final zero in _unicodeZeros) {
        if (unit >= zero && unit <= zero + 9) {
          ascii = 0x30 + unit - zero;
          break;
        }
      }
    }
    if (ascii != null) (codeUnits ??= text.codeUnits.toList())[i] = ascii;
  }
  return codeUnits == null ? text : String.fromCharCodes(codeUnits);
}

// The parameters named `countries` hide the full list.
List<Country> get _allCountries => countries;

/// Removes [prefix] from the start of [value], skipping separators such as
/// spaces or dashes between its digits.
String _stripPrefix(String value, String prefix) {
  var matched = 0;
  var index = 0;
  while (index < value.length && matched < prefix.length) {
    final char = value[index];
    if (char == prefix[matched]) {
      matched++;
    } else if (!_leadingSeparators.hasMatch(char)) {
      return value;
    }
    index++;
  }
  return matched == prefix.length ? value.substring(index) : value;
}

/// Resolves a country's display name for [languageCode], tolerating casing and
/// separator differences (`pt-br`, `PT_BR` and `pt_BR` all work).
String localizedCountryName(Country country, String languageCode) {
  for (final key in _translationKeys(languageCode)) {
    final name = country.nameTranslations[key];
    if (name != null) return name;
  }
  return country.name;
}

final Map<String, List<String>> _translationKeysCache = {};

List<String> _translationKeys(String languageCode) {
  return _translationKeysCache.putIfAbsent(languageCode, () {
    final parts = languageCode.split(RegExp('[-_]'));
    final language = parts.first.toLowerCase();
    final keys = <String>{languageCode, language};
    if (parts.length > 1) {
      final subtag = parts[1];
      if (subtag.length == 4) {
        keys.add('$language-${subtag[0].toUpperCase()}${subtag.substring(1).toLowerCase()}');
      } else {
        keys.add('${language}_${subtag.toUpperCase()}');
      }
    }
    // Most specific first.
    return keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  });
}

/// Search keys for a country, computed once per [Country] instance.
final Expando<List<String>> _searchKeys = Expando<List<String>>('intl_phone_field2.searchKeys');

List<String> countrySearchKeys(Country country) {
  return _searchKeys[country] ??= {
    removeDiacritics(country.name.toLowerCase()),
    for (final translation in country.nameTranslations.values) removeDiacritics(translation.toLowerCase()),
  }.toList(growable: false);
}

/// Sorted, searchable view over a list of countries, used by the pickers.
///
/// Sorting and name normalisation happen once, so filtering on every keystroke
/// stays cheap.
class CountryFilter {
  CountryFilter(List<Country> countries, this.languageCode) {
    for (final country in countries) {
      final name = localizedCountryName(country, languageCode);
      _names[country] = name;
      _sortKeys[country] = removeDiacritics(name.toLowerCase());
    }
    all = List<Country>.unmodifiable(countries.toList()..sort((a, b) => _sortKeys[a]!.compareTo(_sortKeys[b]!)));
  }

  final String languageCode;
  final Map<Country, String> _names = {};

  /// Normalized display names, used for sorting and ranking.
  final Map<Country, String> _sortKeys = {};

  /// All countries sorted by their localized name.
  late final List<Country> all;

  String nameOf(Country country) => _names[country] ?? localizedCountryName(country, languageCode);

  /// Countries matching [query] in any language, ordered by relevance and then
  /// alphabetically. Countries whose ISO code equals the query, or whose
  /// displayed or English name starts with it, come first.
  List<Country> filter(String query) {
    final normalized = removeDiacritics(query.trim().toLowerCase());
    if (normalized.isEmpty) return all;

    final isDialCode = normalized.startsWith('+') || isNumeric(normalized);
    if (isDialCode) {
      final digits = normalized.replaceAll(_nonDigits, '');
      return all.where((country) => country.fullCountryCode.startsWith(digits)).toList(growable: false);
    }

    final prefixMatches = <Country>[];
    final otherMatches = <Country>[];
    for (final country in all) {
      final keys = countrySearchKeys(country);
      if (country.code.toLowerCase() == normalized ||
          _sortKeys[country]!.startsWith(normalized) ||
          keys.first.startsWith(normalized)) {
        prefixMatches.add(country);
      } else if (keys.any((key) => key.contains(normalized))) {
        otherMatches.add(country);
      }
    }
    return [...prefixMatches, ...otherMatches];
  }
}
