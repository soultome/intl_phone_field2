import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoListTile, CupertinoSearchTextField;
import 'package:intl_phone_field_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl_phone_field2/country_picker_dialog.dart';
import 'package:intl_phone_field2/cupertino_country_picker.dart';
import 'package:intl_phone_field2/cupertino_intl_phone_field.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Material and Cupertino examples pick a country', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('+91'), findsOneWidget);

    await tester.tap(find.text('+91'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.byType(CountryPickerDialog), matching: find.byType(TextField)),
      'japan',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Japan'));
    await tester.pumpAndSettle();
    expect(find.text('+81'), findsOneWidget);

    await tester.tap(find.text('Cupertino'));
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('+44'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'brazil');
    await tester.pump();
    await tester.tap(find.widgetWithText(CupertinoListTile, 'Brazil'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoCountryPicker), findsNothing);
    expect(find.text('+55'), findsOneWidget);

    await tester.tap(find.text('Adaptive'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('iOS'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(CupertinoIntlPhoneField), findsOneWidget);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a number'), findsOneWidget);
  });
}
