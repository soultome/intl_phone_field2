import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/cupertino_country_picker.dart';
import 'package:intl_phone_field2/cupertino_intl_phone_field.dart';
import 'package:intl_phone_field2/phone_number.dart';

Widget wrap(Widget child, {Key? formKey}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: SafeArea(
        child: Form(key: formKey, child: child),
      ),
    ),
  );
}

Finder get countryButton => find.byType(CupertinoButton).first;

void main() {
  testWidgets('parses the initial international number', (tester) async {
    await tester.pumpWidget(wrap(const CupertinoIntlPhoneField(initialValue: '+447891234567')));
    expect(find.text('+44'), findsOneWidget);
    expect(find.text('7891234567'), findsOneWidget);
  });

  testWidgets('picks a country from the sheet', (tester) async {
    Country? changedCountry;
    PhoneNumber? changedNumber;
    await tester.pumpWidget(
      wrap(
        CupertinoIntlPhoneField(
          initialCountryCode: 'US',
          initialValue: '612345678',
          onCountryChanged: (country) => changedCountry = country,
          onChanged: (phone) => changedNumber = phone,
        ),
      ),
    );

    await tester.tap(countryButton);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoCountryPicker), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'nether');
    await tester.pump();
    await tester.tap(find.widgetWithText(CupertinoListTile, 'Netherlands'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoCountryPicker), findsNothing);
    expect(find.text('+31'), findsOneWidget);
    expect(changedCountry?.code, 'NL');
    expect(changedNumber?.completeNumber, '+31612345678');
  });

  testWidgets('marks the selected country in the sheet', (tester) async {
    await tester.pumpWidget(wrap(const CupertinoIntlPhoneField(initialCountryCode: 'AF')));
    await tester.tap(countryButton);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(CupertinoListTile, 'Afghanistan'),
        matching: find.byIcon(CupertinoIcons.check_mark),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cancel closes the sheet without changing the country', (tester) async {
    await tester.pumpWidget(wrap(const CupertinoIntlPhoneField(initialCountryCode: 'FR')));
    await tester.tap(countryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoCountryPicker), findsNothing);
    expect(find.text('+33'), findsOneWidget);
  });

  testWidgets('validates inside a Form and resets', (tester) async {
    final formKey = GlobalKey<FormState>();
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(
        CupertinoIntlPhoneField(
          initialCountryCode: 'GB',
          initialValue: '7891234567',
          validator: (phone) => phone!.number.startsWith('0') ? 'No leading zero' : null,
          onChanged: (phone) => changes.add(phone.number),
        ),
        formKey: formKey,
      ),
    );

    await tester.enterText(find.byType(CupertinoTextField), '123');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Invalid Mobile Number'), findsOneWidget);

    await tester.enterText(find.byType(CupertinoTextField), '0891234567');
    await tester.pumpAndSettle();
    expect(find.text('No leading zero'), findsOneWidget);

    formKey.currentState!.reset();
    await tester.pumpAndSettle();
    expect(find.text('No leading zero'), findsNothing);
    expect(find.text('7891234567'), findsOneWidget);
    expect(changes.last, '7891234567');
  });

  testWidgets('stays in sync with a provided controller', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();
    PhoneNumber? saved;
    await tester.pumpWidget(
      wrap(
        CupertinoIntlPhoneField(controller: controller, initialCountryCode: 'IN', onSaved: (phone) => saved = phone),
        formKey: formKey,
      ),
    );

    controller.text = '9876543210';
    await tester.pump();
    formKey.currentState!.save();
    expect(saved?.completeNumber, '+919876543210');
  });

  testWidgets('does not open the picker when disabled', (tester) async {
    await tester.pumpWidget(wrap(const CupertinoIntlPhoneField(enabled: false)));
    await tester.tap(countryButton);
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoCountryPicker), findsNothing);
  });

  testWidgets('selects the country of an autofilled number', (tester) async {
    final formKey = GlobalKey<FormState>();
    final countryChanges = <String>[];
    final changes = <String>[];
    await tester.pumpWidget(
      wrap(
        CupertinoIntlPhoneField(
          initialCountryCode: 'US',
          onCountryChanged: (country) => countryChanges.add(country.code),
          onChanged: (phone) => changes.add(phone.completeNumber),
        ),
        formKey: formKey,
      ),
    );

    // iOS autofills the number as saved in Contacts, with its country code.
    await tester.enterText(find.byType(CupertinoTextField), '+977 984-123 4567');
    await tester.pump();

    expect(fieldText(tester), '9841234567');
    expect(find.text('+977'), findsOneWidget);
    expect(countryChanges, ['NP']);
    expect(changes, ['+9779841234567']);
    expect(formKey.currentState!.validate(), isTrue);
  }, variant: TargetPlatformVariant.all());

  testWidgets('reads a number filled into an unfocused field, as an AutofillGroup does on iOS', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    PhoneNumber? saved;
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      wrap(
        CupertinoIntlPhoneField(controller: controller, initialCountryCode: 'US', onSaved: (phone) => saved = phone),
        formKey: formKey,
      ),
    );

    tester
        .state<EditableTextState>(find.byType(EditableText))
        .autofill(const TextEditingValue(text: '+44 (0)7911 123456', selection: TextSelection.collapsed(offset: 18)));
    await tester.pump();

    expect(controller.text, '7911123456');
    formKey.currentState!.save();
    expect(saved?.completeNumber, '+447911123456');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('limits autofilled and typed numbers to the country length', (tester) async {
    await tester.pumpWidget(wrap(const CupertinoIntlPhoneField(initialCountryCode: 'US')));

    await tester.enterText(find.byType(CupertinoTextField), '+49 1512 3456789');
    await tester.pump();
    expect(fieldText(tester), '15123456789');

    await tester.enterText(find.byType(CupertinoTextField), '+1 202 555 0123');
    await tester.pump();
    expect(fieldText(tester), '2025550123');
    expect(find.text('+1'), findsOneWidget);

    await tester.showKeyboard(find.byType(CupertinoTextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: '20255501234', selection: TextSelection.collapsed(offset: 11)),
    );
    await tester.pump();
    expect(fieldText(tester), '2025550123');
  });
}

String fieldText(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).controller.text;
