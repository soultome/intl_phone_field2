import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoColors, CupertinoFormSection, CupertinoTheme, CupertinoThemeData;
import 'package:intl_phone_field2/cupertino_intl_phone_field.dart';
import 'package:intl_phone_field2/intl_phone_field.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('Phone Field Example')),
        body: switch (_tab) {
          0 => const MaterialExample(),
          1 => const CupertinoExample(),
          _ => const AdaptiveExample(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.android), label: 'Material'),
            NavigationDestination(icon: Icon(Icons.phone_iphone), label: 'Cupertino'),
            NavigationDestination(icon: Icon(Icons.devices), label: 'Adaptive'),
          ],
        ),
      ),
    );
  }
}

class MaterialExample extends StatefulWidget {
  const MaterialExample({super.key});

  @override
  State<MaterialExample> createState() => _MaterialExampleState();
}

class _MaterialExampleState extends State<MaterialExample> {
  final _formKey = GlobalKey<FormState>();
  String _number = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const TextField(
            decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          IntlPhoneField(
            initialCountryCode: 'IN',
            positionedPopup: true,
            decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            onChanged: (phone) => setState(() => _number = phone.completeNumber),
            onCountryChanged: (country) => debugPrint('Country changed to: ${country.name}'),
          ),
          const SizedBox(height: 8),
          Text('Complete number: $_number'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => _formKey.currentState?.validate(), child: const Text('Submit')),
        ],
      ),
    );
  }
}

class CupertinoExample extends StatefulWidget {
  const CupertinoExample({super.key});

  @override
  State<CupertinoExample> createState() => _CupertinoExampleState();
}

class _CupertinoExampleState extends State<CupertinoExample> {
  final _formKey = GlobalKey<FormState>();
  String _number = '';

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(brightness: Theme.of(context).brightness),
      child: ColoredBox(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoIntlPhoneField(
                  initialCountryCode: 'US',
                  placeholder: 'Phone number',
                  onChanged: (phone) => setState(() => _number = phone.completeNumber),
                ),
              ),
              CupertinoFormSection.insetGrouped(
                header: const Text('IN A FORM SECTION'),
                children: const <Widget>[
                  // Without a decoration the field blends into the section.
                  CupertinoIntlPhoneField(
                    initialValue: '+447891234567',
                    decoration: null,
                    placeholder: 'Phone number',
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                ],
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Complete number: $_number')),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(onPressed: () => _formKey.currentState?.validate(), child: const Text('Submit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `IntlPhoneField.adaptive` renders the Cupertino field on iOS and macOS and
/// the Material field elsewhere. The toggle overrides the theme's platform to
/// preview both.
class AdaptiveExample extends StatefulWidget {
  const AdaptiveExample({super.key});

  @override
  State<AdaptiveExample> createState() => _AdaptiveExampleState();
}

class _AdaptiveExampleState extends State<AdaptiveExample> {
  final _formKey = GlobalKey<FormState>();
  TargetPlatform? _platform;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = _platform ?? theme.platform;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SegmentedButton<TargetPlatform>(
            segments: const [
              ButtonSegment(value: TargetPlatform.android, label: Text('Android')),
              ButtonSegment(value: TargetPlatform.iOS, label: Text('iOS')),
            ],
            selected: {platform == TargetPlatform.iOS ? TargetPlatform.iOS : TargetPlatform.android},
            onSelectionChanged: (selection) => setState(() => _platform = selection.single),
          ),
          const SizedBox(height: 16),
          Theme(
            data: theme.copyWith(platform: platform),
            child: IntlPhoneField.adaptive(
              // A new key per platform, so switching starts a fresh field.
              key: ValueKey(platform),
              initialCountryCode: 'DE',
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              validator: (phone) => phone == null || phone.number.isEmpty ? 'Please enter a number' : null,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => _formKey.currentState?.validate(), child: const Text('Submit')),
        ],
      ),
    );
  }
}
