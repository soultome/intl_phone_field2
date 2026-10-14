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
