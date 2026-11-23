import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../countries.dart';
import 'country_utils.dart';

/// Input formatting shared by the Material and Cupertino phone fields.
///
/// A number entered all at once, by autofill or a paste, is reduced to its
/// national number. iOS autofills the number saved in Contacts as it is stored
/// there, usually with its country code and formatting, such as
/// `+977 984-1234567`. When that dial code belongs to another country in the
/// list, [onCountryDetected] selects it.
///
/// The country's length limit is applied here, instead of by the text field's
/// `maxLength`, which would still limit an autofilled number to the previous
/// country's length.
class PhoneFieldInput {
  PhoneFieldInput({required this.countries, required this.selectedCountry, required this.onCountryDetected});

  final List<Country> Function() countries;
  final Country Function() selectedCountry;

  /// Called at the end of an edit whose number belongs to another country.
  ///
  /// [textChanged] is `false` when the text is the same as before the edit, in
  /// which case the text field doesn't call its `onChanged`.
  final void Function(Country country, {required bool textChanged}) onCountryDetected;

  late final TextInputFormatter _wholeNumberFormatter = TextInputFormatter.withFunction(_readWholeNumber);

  // Passed from the first formatter of an edit to the last one.
  Country? _detectedCountry;

  /// The text field's formatters.
  ///
  /// [inputFormatters] run after an autofilled number is read, so that one
  /// such as `FilteringTextInputFormatter.digitsOnly` doesn't remove its `+`.
  /// The length limit runs last, like the text field's own.
  List<TextInputFormatter> formatters({
    required List<TextInputFormatter>? inputFormatters,
    required bool limitLength,
    required MaxLengthEnforcement maxLengthEnforcement,
  }) {
    return [
      _wholeNumberFormatter,
      ...?inputFormatters,
      TextInputFormatter.withFunction(
        (oldValue, newValue) => _finishEdit(oldValue, newValue, limitLength ? maxLengthEnforcement : null),
      ),
    ];
  }

  TextEditingValue _readWholeNumber(TextEditingValue oldValue, TextEditingValue newValue) {
    _detectedCountry = null;
    // Text that a keyboard is still composing isn't final; changing it would
    // fight the keyboard.
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) return newValue;
    // Typing inserts one character at a time; autofill and paste insert more.
    if (_insertedLength(oldValue.text, newValue.text) < 2) return newValue;

    final current = selectedCountry();
    final parsed = parsePhoneNumberInput(
      countries: countries(),
      selectedCountry: current,
      text: newValue.text,
      cursor: newValue.selection.isValid ? newValue.selection.end : null,
    );
    if (parsed == null) return newValue;
    if (!isSameCountry(parsed.country, current)) _detectedCountry = parsed.country;
    if (parsed.number == newValue.text) return newValue;
    return TextEditingValue(
      text: parsed.number,
      selection: TextSelection.collapsed(offset: parsed.cursor),
    );
  }

  TextEditingValue _finishEdit(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    MaxLengthEnforcement? maxLengthEnforcement,
  ) {
    final detectedCountry = _detectedCountry;
    _detectedCountry = null;

    var value = newValue;
    final maxLength = (detectedCountry ?? selectedCountry()).maxLength;
    // Text with no more UTF-16 code units than the limit can't have more
    // characters either, so most keystrokes skip the limiter.
    if (maxLengthEnforcement != null && value.text.length > maxLength) {
      value = LengthLimitingTextInputFormatter(
        maxLength,
        maxLengthEnforcement: maxLengthEnforcement,
      ).formatEditUpdate(oldValue, value);
    }

    final textChanged = value.text != oldValue.text;
    // When the limit rejects a new number, the old one keeps its country.
    final rejected = !textChanged && newValue.text != oldValue.text;
    if (detectedCountry != null && !rejected) onCountryDetected(detectedCountry, textChanged: textChanged);
    return value;
  }
}

/// The number of characters an edit inserted, not counting the text it left
/// unchanged before and after them.
int _insertedLength(String oldText, String newText) {
  final shorter = math.min(oldText.length, newText.length);
  var prefix = 0;
  while (prefix < shorter && oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < shorter - prefix &&
      oldText.codeUnitAt(oldText.length - 1 - suffix) == newText.codeUnitAt(newText.length - 1 - suffix)) {
    suffix++;
  }
  return newText.length - prefix - suffix;
}
