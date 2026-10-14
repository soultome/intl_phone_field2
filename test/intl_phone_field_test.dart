import 'dart:async';

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

      await tester.enterText(find.byType(TextField), '78912 3456');
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
}
