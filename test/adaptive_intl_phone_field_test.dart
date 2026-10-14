import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoIcons, CupertinoListTile, CupertinoSearchTextField, CupertinoTextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field2/country_picker_dialog.dart';
import 'package:intl_phone_field2/cupertino_country_picker.dart';
import 'package:intl_phone_field2/cupertino_intl_phone_field.dart';
import 'package:intl_phone_field2/intl_phone_field.dart';
import 'package:material_ui/material_ui.dart';

Widget wrap(TargetPlatform platform, Widget child, {Key? formKey}) {
  return MaterialApp(
    theme: ThemeData(platform: platform),
    home: Scaffold(
      body: Form(key: formKey, child: child),
    ),
  );
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('uses the Material field on ${platform.name}', (tester) async {
      await tester.pumpWidget(
        wrap(
          platform,
          const IntlPhoneField.adaptive(
            initialCountryCode: 'GB',
            decoration: InputDecoration(labelText: 'Phone'),
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CupertinoIntlPhoneField), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);

      await tester.tap(find.text('+44'));
      await tester.pumpAndSettle();
      expect(find.byType(CountryPickerDialog), findsOneWidget);
    });
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    testWidgets('uses the Cupertino field on ${platform.name}', (tester) async {
      await tester.pumpWidget(
        wrap(
          platform,
          const IntlPhoneField.adaptive(
            initialCountryCode: 'GB',
            decoration: InputDecoration(labelText: 'Phone'),
          ),
        ),
      );
      expect(find.byType(CupertinoIntlPhoneField), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      // labelText becomes the placeholder, and icons follow the platform.
      expect(tester.widget<CupertinoTextField>(find.byType(CupertinoTextField)).placeholder, 'Phone');
      expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });
  }

  testWidgets('Cupertino mode picks a country and reports it through the state', (tester) async {
    final key = GlobalKey<IntlPhoneFieldState>();
    String? changed;
    await tester.pumpWidget(
      wrap(
        TargetPlatform.iOS,
        IntlPhoneField.adaptive(
          key: key,
          initialCountryCode: 'US',
          initialValue: '612345678',
          onCountryChanged: (country) => changed = country.code,
        ),
      ),
    );

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoCountryPicker), findsOneWidget);

    await tester.enterText(find.byType(CupertinoSearchTextField), 'nether');
    await tester.pump();
    await tester.tap(find.widgetWithText(CupertinoListTile, 'Netherlands'));
    await tester.pumpAndSettle();

    expect(changed, 'NL');
    expect(key.currentState!.selectedCountry.code, 'NL');
    expect(key.currentState!.phoneNumber.completeNumber, '+31612345678');
  });

  testWidgets('Cupertino mode validates inside a Form', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      wrap(
        TargetPlatform.iOS,
        IntlPhoneField.adaptive(
          initialCountryCode: 'GB',
          validator: (phone) => phone!.number.isEmpty ? 'Required' : null,
        ),
        formKey: formKey,
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(find.byType(CupertinoTextField), '123');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Invalid Mobile Number'), findsOneWidget);
  });

  testWidgets('explicit options are kept on every platform', (tester) async {
    const field = IntlPhoneField.adaptive(
      dropdownIcon: Icon(Icons.expand_more),
      dropdownIconPosition: IconPosition.trailing,
    );
    await tester.pumpWidget(wrap(TargetPlatform.iOS, field));
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    await tester.pumpWidget(wrap(TargetPlatform.android, field));
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
