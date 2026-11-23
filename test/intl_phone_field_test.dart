import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/intl_phone_field.dart';
import 'package:intl_phone_field2/phone_number.dart';
import 'package:material_ui/material_ui.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key, required this.phoneNumber, this.countryCode});

  final String phoneNumber;
  final String? countryCode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Intl Phone Field',
      home: Scaffold(
        appBar: AppBar(title: const Text("")),
        body: IntlPhoneField(initialValue: phoneNumber, initialCountryCode: countryCode),
      ),
    );
  }
}

Widget wrap(Widget child, {Key? formKey}) {
  return MaterialApp(
    home: Scaffold(
      body: Form(key: formKey, child: child),
    ),
  );
}

Finder get flagButton => find.byType(InkWell).first;

String fieldText(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  testWidgets('Test intl_phone_field setup with completeNumber', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidget(phoneNumber: '+447891234467'));

    final countryCodeFinder = find.text('+44');
    final numberFinder = find.text('7891234467');

    expect(countryCodeFinder, findsOneWidget);
    expect(numberFinder, findsOneWidget);
  });

  testWidgets('Test intl_phone_field setup with Guernsey number: +441481960194', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidget(phoneNumber: '+441481960194', countryCode: 'GG'));

    final countryCodeFinder = find.text('+44 1481');
    final numberFinder = find.text('960194');

    expect(countryCodeFinder, findsOneWidget);
    expect(numberFinder, findsOneWidget);
  });

  testWidgets('Test intl_phone_field setup with UK number: +447891244567', (WidgetTester tester) async {
    await tester.pumpWidget(const TestWidget(phoneNumber: '+447891244567', countryCode: 'GB'));

    final countryCodeFinder = find.text('+44');
    final numberFinder = find.text('7891244567');

    expect(countryCodeFinder, findsOneWidget);
    expect(numberFinder, findsOneWidget);
  });

  group('initial value', () {
    testWidgets('uses the longest matching dial code', (tester) async {
      await tester.pumpWidget(const TestWidget(phoneNumber: '+18765551234'));
      expect(find.text('+1876'), findsOneWidget);
      expect(find.text('5551234'), findsOneWidget);
    });

    testWidgets('picks the primary country for a shared dial code', (tester) async {
      final key = GlobalKey<IntlPhoneFieldState>();
      await tester.pumpWidget(wrap(IntlPhoneField(key: key, initialValue: '+79161234567')));
      expect(key.currentState!.selectedCountry.code, 'RU');
    });

    testWidgets('accepts a dial code as initialCountryCode', (tester) async {
      await tester.pumpWidget(const TestWidget(phoneNumber: '', countryCode: '+225'));
      expect(find.text('+225'), findsOneWidget);
    });

    testWidgets('keeps a national number that starts with the dial code', (tester) async {
      await tester.pumpWidget(const TestWidget(phoneNumber: '9123456789', countryCode: 'IN'));
      expect(find.text('9123456789'), findsOneWidget);
    });

    testWidgets('strips the country code from a national value that is too long', (tester) async {
      await tester.pumpWidget(const TestWidget(phoneNumber: '919876543210', countryCode: 'IN'));
      expect(find.text('9876543210'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('AutovalidateMode.always without a validator does not throw', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(autovalidateMode: AutovalidateMode.always)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('runs the validator on Form.validate without any typing', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(validator: (phone) => phone == null || phone.number.isEmpty ? 'Required' : null),
          formKey: formKey,
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('rejects numbers with the wrong length or non-digits', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'GB'), formKey: formKey));

      await tester.enterText(find.byType(TextField), '123');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Invalid Mobile Number'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '78912*3456');
      expect(formKey.currentState!.validate(), isFalse);

      await tester.enterText(find.byType(TextField), '7891234567');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('shows the result of an async validator once it completes', (tester) async {
      final completer = Completer<String?>();
      var calls = 0;
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(
            initialCountryCode: 'GB',
            validator: (phone) {
              calls++;
              return completer.future;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '7891234567');
      await tester.pump();
      expect(find.text('Number taken'), findsNothing);

      completer.complete('Number taken');
      await tester.pump();
      await tester.pump();
      expect(find.text('Number taken'), findsOneWidget);
      // Re-validating the same number reuses the result.
      expect(calls, 1);
    });

    testWidgets('calls onChanged synchronously even with an async validator', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(
            initialCountryCode: 'GB',
            validator: (phone) => Completer<String?>().future,
            onChanged: (phone) => changes.add(phone.completeNumber),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '7');
      expect(changes, ['+447']);
    });
  });

  group('country picker', () {
    testWidgets('search and selection update the field', (tester) async {
      Country? changedCountry;
      PhoneNumber? changedNumber;
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(
            initialCountryCode: 'US',
            initialValue: '7891234567',
            onCountryChanged: (country) => changedCountry = country,
            onChanged: (phone) => changedNumber = phone,
          ),
        ),
      );

      await tester.tap(flagButton);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), '+44');
      await tester.pump();
      expect(find.text('United Kingdom'), findsOneWidget);
      expect(find.text('Guernsey'), findsOneWidget);
      expect(find.text('Canada'), findsNothing);

      await tester.tap(find.text('United Kingdom'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('+44'), findsOneWidget);
      expect(changedCountry?.code, 'GB');
      expect(changedNumber?.completeNumber, '+447891234567');
    });

    testWidgets('search ignores diacritics and ranks prefix matches first', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField()));
      await tester.tap(flagButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), 'aland');
      await tester.pump();
      expect(find.text('Åland Islands'), findsOneWidget);

      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), 'in');
      await tester.pump();
      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .take(2)
          .toList();
      expect(titles, ['India', 'Indonesia']);
    });

    testWidgets('shows names in the requested language', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(languageCode: 'pt-br', initialCountryCode: 'DE')));
      await tester.tap(flagButton);
      await tester.pumpAndSettle();
      expect(find.text('Alemanha'), findsOneWidget);
    });

    testWidgets('does not open when readOnly or disabled', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(readOnly: true)));
      await tester.tap(flagButton);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      await tester.pumpWidget(wrap(const IntlPhoneField(enabled: false)));
      await tester.tap(flagButton);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('positioned popup stays on screen above a field at the bottom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Spacer(),
                IntlPhoneField(positionedPopup: true, key: UniqueKey()),
              ],
            ),
          ),
        ),
      );

      await tester.tap(flagButton);
      await tester.pumpAndSettle();

      final popup = tester.getRect(find.ancestor(of: find.text('Afghanistan'), matching: find.byType(Material)).last);
      final field = tester.getRect(find.byType(TextField).first);
      final screen = Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(screen.contains(popup.topLeft) && screen.contains(popup.bottomRight - const Offset(1, 1)), isTrue);
      expect(popup.bottom, lessThanOrEqualTo(field.top));
      // Aligned with the field, inset by the 8px screen margin.
      expect(popup.left, field.left + 8);
    });

    testWidgets('selecting with a controller reports the controller text', (tester) async {
      final controller = TextEditingController(text: '612345678');
      addTearDown(controller.dispose);
      PhoneNumber? changed;
      await tester.pumpWidget(
        wrap(IntlPhoneField(controller: controller, initialCountryCode: 'US', onChanged: (phone) => changed = phone)),
      );

      await tester.tap(flagButton);
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), 'Netherlands');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Netherlands'));
      await tester.pumpAndSettle();

      expect(changed?.completeNumber, '+31612345678');
      expect(fieldText(tester), '612345678');
    });
  });

  // tester.enterText replaces the whole text at once, like autofill or a paste.
  group('autofill', () {
    testWidgets('selects the country of an autofilled number and keeps its national number', (tester) async {
      final formKey = GlobalKey<FormState>();
      final countryChanges = <String>[];
      final changes = <String>[];
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(
            initialCountryCode: 'US',
            onCountryChanged: (country) => countryChanges.add(country.code),
            onChanged: (phone) => changes.add(phone.completeNumber),
          ),
          formKey: formKey,
        ),
      );

      await tester.enterText(find.byType(TextField), '+977 984-123 4567');
      await tester.pump();

      expect(fieldText(tester), '9841234567');
      expect(find.text('+977'), findsOneWidget);
      expect(tester.state<IntlPhoneFieldState>(find.byType(IntlPhoneField)).selectedCountry.code, 'NP');
      expect(countryChanges, ['NP']);
      expect(changes, ['+9779841234567']);
      expect(formKey.currentState!.validate(), isTrue);
    }, variant: TargetPlatformVariant.all());

    testWidgets('keeps the selected country for its own dial code', (tester) async {
      final countryChanges = <String>[];
      await tester.pumpWidget(
        wrap(IntlPhoneField(initialCountryCode: 'CA', onCountryChanged: (country) => countryChanges.add(country.code))),
      );

      await tester.enterText(find.byType(TextField), '+1 (416) 555-0123');
      await tester.pump();

      expect(fieldText(tester), '4165550123');
      expect(tester.state<IntlPhoneFieldState>(find.byType(IntlPhoneField)).selectedCountry.code, 'CA');
      expect(countryChanges, isEmpty);
    });

    testWidgets('limits the number to the length of the new country', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US')));

      // Germany allows longer numbers than the US.
      await tester.enterText(find.byType(TextField), '+49 1512 3456789');
      await tester.pump();
      expect(fieldText(tester), '15123456789');
      expect(find.text('11/13'), findsOneWidget);
    });

    testWidgets('replaces a full field', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US')));
      await tester.enterText(find.byType(TextField), '2025550123');

      await tester.enterText(find.byType(TextField), '+44 7911 123456');
      await tester.pump();
      expect(fieldText(tester), '7911123456');
      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('calls onChanged when only the country changes', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        wrap(IntlPhoneField(initialCountryCode: 'IN', onChanged: (phone) => changes.add(phone.completeNumber))),
      );
      await tester.enterText(find.byType(TextField), '9841234567');
      changes.clear();

      await tester.enterText(find.byType(TextField), '+977 9841234567');
      await tester.pump();
      expect(fieldText(tester), '9841234567');
      expect(changes, ['+9779841234567']);
    });

    testWidgets('keeps the selected country when the dial code is not in the list', (tester) async {
      final formKey = GlobalKey<FormState>();
      final countryChanges = <String>[];
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(
            initialCountryCode: 'NP',
            countries: countries.where((c) => c.code == 'NP' || c.code == 'IN').toList(),
            onCountryChanged: (country) => countryChanges.add(country.code),
          ),
          formKey: formKey,
        ),
      );

      await tester.enterText(find.byType(TextField), '+1 202 555 0123');
      await tester.pump();

      expect(find.text('+977'), findsOneWidget);
      expect(countryChanges, isEmpty);
      // The dial code stays, so the number isn't mistaken for a Nepali one.
      expect(fieldText(tester), startsWith('+1202'));
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('reads the number before custom inputFormatters', (tester) async {
      await tester.pumpWidget(
        wrap(IntlPhoneField(initialCountryCode: 'US', inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
      );

      await tester.enterText(find.byType(TextField), '+977 984-123 4567');
      await tester.pump();
      expect(fieldText(tester), '9841234567');
      expect(find.text('+977'), findsOneWidget);
    });

    testWidgets('leaves typed characters alone and still limits their length', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US')));

      await typeOneByOne(tester, '+977');
      expect(fieldText(tester), '+977');
      expect(find.text('+1'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await typeOneByOne(tester, '20255501234');
      expect(fieldText(tester), '2025550123');
    }, variant: TargetPlatformVariant.all());

    testWidgets('reads a number filled into an unfocused field, as an AutofillGroup does on iOS', (tester) async {
      Country? changedCountry;
      await tester.pumpWidget(
        wrap(IntlPhoneField(initialCountryCode: 'US', onCountryChanged: (country) => changedCountry = country)),
      );
      expect(tester.binding.focusManager.primaryFocus?.context?.widget, isNot(isA<EditableText>()));

      tester.state<EditableTextState>(find.byType(EditableText)).autofill(_atEnd('+977 984-123 4567'));
      await tester.pump();

      expect(fieldText(tester), '9841234567');
      expect(changedCountry?.code, 'NP');
    });

    testWidgets('keeps the number when onCountryChanged clears the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        wrap(
          IntlPhoneField(
            controller: controller,
            initialCountryCode: 'US',
            // Common to reset the number when the user picks another country.
            onCountryChanged: (_) => controller.clear(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '+977 984-123 4567');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.text, '9841234567');
      expect(find.text('+977'), findsOneWidget);
    });

    testWidgets('keeps the old number and country when the new number is too long', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US')));
      await typeOneByOne(tester, '2025550123');

      tester.testTextInput.updateEditingValue(_atEnd('+44 7911 1234567'));
      await tester.pump();

      expect(fieldText(tester), '2025550123');
      expect(find.text('+1'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('ignores autofill in a read-only field', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US', readOnly: true)));

      tester.state<EditableTextState>(find.byType(EditableText)).autofill(_atEnd('+977 9841234567'));
      await tester.pump();

      expect(fieldText(tester), '');
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('autofills repeatedly and resets', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US'), formKey: formKey));

      for (final (number, dialCode, national) in [
        ('+977 9841234567', '+977', '9841234567'),
        ('0044 7911 123456', '+44', '7911123456'),
        ('+1 (202) 555-0123,45', '+1', '2025550123'),
      ]) {
        await tester.enterText(find.byType(TextField), number);
        await tester.pump();
        expect(fieldText(tester), national);
        expect(find.text(dialCode), findsOneWidget);
        expect(formKey.currentState!.validate(), isTrue);
      }

      formKey.currentState!.reset();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(fieldText(tester), '');
    });

    testWidgets('does not limit the length when disableLengthCheck is set', (tester) async {
      await tester.pumpWidget(wrap(const IntlPhoneField(initialCountryCode: 'US', disableLengthCheck: true)));

      await tester.enterText(find.byType(TextField), '+44 7911 123456 789');
      await tester.pump();
      expect(fieldText(tester), '7911123456789');
      expect(find.text('+44'), findsOneWidget);
    });
  });
}

TextEditingValue _atEnd(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

/// Types [text] one character at a time, like a keyboard.
Future<void> typeOneByOne(WidgetTester tester, String text) async {
  await tester.showKeyboard(find.byType(EditableText));
  for (final char in text.split('')) {
    final next = fieldText(tester) + char;
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      ),
    );
    await tester.pump();
  }
}
