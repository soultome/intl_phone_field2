import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/src/phone_input.dart';

Country country(String code) => countries.firstWhere((c) => c.code == code);

/// Runs [PhoneFieldInput]'s formatters like a text field does.
class Harness {
  Harness(
    String code, {
    List<Country>? available,
    this.limitLength = true,
    this.enforcement = MaxLengthEnforcement.enforced,
    this.inputFormatters,
  }) : selected = country(code) {
    input = PhoneFieldInput(
      countries: () => available ?? countries,
      selectedCountry: () => selected,
      onCountryDetected: (country, {required textChanged}) {
        selected = country;
        detections.add((country.code, textChanged));
      },
    );
  }

  late final PhoneFieldInput input;
  final bool limitLength;
  final MaxLengthEnforcement enforcement;
  final List<TextInputFormatter>? inputFormatters;
  Country selected;
  final detections = <(String, bool)>[];

  TextEditingValue edit(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatters = input.formatters(
      inputFormatters: inputFormatters,
      limitLength: limitLength,
      maxLengthEnforcement: enforcement,
    );
    return formatters.fold(newValue, (value, formatter) => formatter.formatEditUpdate(oldValue, value));
  }

  TextEditingValue replace(String oldText, String newText) => edit(_atEnd(oldText), _atEnd(newText));
}

TextEditingValue _atEnd(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  test('reports the country with whether the text changed', () {
    final harness = Harness('IN');
    expect(harness.replace('', '+977 984-123 4567').text, '9841234567');
    expect(harness.detections, [('NP', true)]);

    final sameText = Harness('IN');
    expect(sameText.replace('9841234567', '+977 9841234567').text, '9841234567');
    expect(sameText.detections, [('NP', false)]);
  });

  test('keeps the old number and its country when the limit rejects the new one', () {
    // Like any too-long edit of a field at its limit (the UK's is the same as
    // the US'), the number is rejected.
    final harness = Harness('US');
    final result = harness.replace('2025550123', '+44 7911 1234567');
    expect(result.text, '2025550123');
    expect(harness.selected.code, 'US');
    expect(harness.detections, isEmpty);
  });

  test('cuts a too-long number to the new country length when the field was not at that limit', () {
    final harness = Harness('US');
    expect(harness.replace('2025550123', '+49 1512 3456789 0123').text, '1512345678901');
    expect(harness.detections, [('DE', true)]);
  });

  test('leaves text that a keyboard is still composing', () {
    final harness = Harness('US', limitLength: false);
    const composing = TextEditingValue(
      text: '+977 9841234567',
      selection: TextSelection.collapsed(offset: 15),
      composing: TextRange(start: 0, end: 15),
    );
    expect(harness.edit(TextEditingValue.empty, composing), composing);
    expect(harness.detections, isEmpty);
  });

  test('a paste in the middle keeps the cursor after the pasted digits', () {
    final harness = Harness('US');
    final result = harness.edit(
      const TextEditingValue(text: '2020123', selection: TextSelection.collapsed(offset: 3)),
      const TextEditingValue(text: '202555-0123', selection: TextSelection.collapsed(offset: 7)),
    );
    expect(result.text, '2025550123');
    expect(result.selection, const TextSelection.collapsed(offset: 6));
  });

  test('a paste into a full field is rejected, as without autofill support', () {
    final harness = Harness('US');
    final result = harness.edit(
      const TextEditingValue(text: '2025550123', selection: TextSelection.collapsed(offset: 3)),
      const TextEditingValue(text: '20299-5550123', selection: TextSelection.collapsed(offset: 6)),
    );
    expect(result.text, '2025550123');
  });

  test('does not limit the length when the length check is disabled', () {
    final harness = Harness('US', limitLength: false);
    expect(harness.replace('', '+44 7911 123456 789').text, '7911123456789');
    expect(harness.selected.code, 'GB');
  });

  test('random edits never throw and leave a valid selection', () {
    final random = Random(11);
    const alphabet = ['0', '1', '2', '4', '7', '9', '+', ' ', '-', '(', ')', ',', 'a', '*'];
    String randomText(int maxLength) =>
        List.generate(random.nextInt(maxLength + 1), (_) => alphabet[random.nextInt(alphabet.length)]).join();
    final limited = [country('NP'), country('IN'), country('GB')];

    for (var i = 0; i < 5000; i++) {
      final enforcement = MaxLengthEnforcement.values[random.nextInt(MaxLengthEnforcement.values.length)];
      final harness = Harness(
        'NP',
        available: random.nextBool() ? null : limited,
        limitLength: random.nextInt(4) != 0,
        enforcement: enforcement,
        inputFormatters: random.nextBool() ? null : [FilteringTextInputFormatter.allow(RegExp(r'[\d+]'))],
      );
      var value = TextEditingValue.empty;
      for (var step = 0; step < 8; step++) {
        final text = value.text;
        final start = text.isEmpty ? 0 : random.nextInt(text.length + 1);
        final end = start + (text.length == start ? 0 : random.nextInt(text.length - start + 1));
        final inserted = random.nextInt(3) == 0 ? randomText(18) : randomText(1);
        final newText = text.replaceRange(start, end, inserted);
        final newValue = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + inserted.length),
        );
        final result = harness.edit(value, newValue);

        final reason = '"$text" -> "$newText" gave "${result.text}" (${harness.selected.code}, $enforcement)';
        expect(result.selection.isValid, isTrue, reason: reason);
        expect(result.selection.start, inInclusiveRange(0, result.text.length), reason: reason);
        expect(result.selection.end, inInclusiveRange(0, result.text.length), reason: reason);
        if (harness.limitLength && enforcement != MaxLengthEnforcement.none && result.text != text) {
          expect(result.text.length, lessThanOrEqualTo(harness.selected.maxLength), reason: reason);
        }
        value = result;
      }
    }
  });
}
