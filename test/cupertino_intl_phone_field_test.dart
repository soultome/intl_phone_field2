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
}
