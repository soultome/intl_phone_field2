# International Phone Field Package
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-9-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

[![pub package](https://img.shields.io/pub/v/intl_phone_field2.svg)](https://pub.dev/packages/intl_phone_field2)

This Package is a fork of "intl_phone_field" (https://pub.dev/packages/intl_phone_field).

This widget can be used to make customised text field to take phone number input for any country along with an option to choose country code from a dropdown. It comes in Material (`IntlPhoneField`), Cupertino (`CupertinoIntlPhoneField`) and adaptive (`IntlPhoneField.adaptive`) styles.

## Screenshots

<img src="https://github.com/vanshg395/intl_phone_field/blob/master/1.png?raw=true" height="500px"> <img src="https://github.com/vanshg395/intl_phone_field/blob/master/2.png?raw=true" height="500px"> <img src="https://github.com/vanshg395/intl_phone_field/blob/master/3.png?raw=true" height="500px">

## Requirements

Version 4 is built on the standalone [`material_ui`](https://pub.dev/packages/material_ui) and [`cupertino_ui`](https://pub.dev/packages/cupertino_ui) packages instead of `package:flutter/material.dart`. It needs Flutter 3.47 / Dart 3.13 or newer.

Your app should use `material_ui` too: types you pass to the field, such as `InputDecoration`, must come from `package:material_ui/material_ui.dart`. To migrate an app, run:

```sh
dart fix --apply --code=migrate_design_widgets
```

If your app can't migrate yet, stay on `intl_phone_field2: ^3.3.3`.

## Installing

```sh
flutter pub add intl_phone_field2
```

## Material

```dart
import 'package:intl_phone_field2/intl_phone_field.dart';
import 'package:material_ui/material_ui.dart';

IntlPhoneField(
  decoration: const InputDecoration(
    labelText: 'Phone Number',
    border: OutlineInputBorder(),
  ),
  initialCountryCode: 'IN',
  onChanged: (phone) {
    print(phone.completeNumber);
  },
)
```

Set `positionedPopup: true` to open the country picker as a dropdown attached to the field instead of a centered dialog.

## Cupertino

```dart
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl_phone_field2/cupertino_intl_phone_field.dart';

CupertinoIntlPhoneField(
  initialCountryCode: 'US',
  placeholder: 'Phone number',
  onChanged: (phone) {
    print(phone.completeNumber);
  },
)
```

The country picker opens in an iOS sheet with search. Pass `decoration: null` for a borderless field, for example inside a `CupertinoFormSection`. Style the picker with `pickerStyle: CupertinoCountryPickerStyle(...)`.

## Adaptive

`IntlPhoneField.adaptive` shows the Cupertino field on iOS and macOS and the Material field everywhere else, based on `Theme.of(context).platform`. It takes the same options as `IntlPhoneField`:

```dart
IntlPhoneField.adaptive(
  decoration: const InputDecoration(labelText: 'Phone Number'),
  initialCountryCode: 'IN',
  onChanged: (phone) => print(phone.completeNumber),
)
```

On iOS and macOS, the decoration's `hintText` (or `labelText`) becomes the placeholder, and `cupertinoDecoration` and `cupertinoPickerStyle` style the field and the picker. Material-only options such as `positionedPopup` are ignored there.

## Common options

Both widgets work inside a `Form`: they support `validator`, `onSaved`, `autovalidateMode` and `FormState.reset()`.

- `initialCountryCode`: ISO code (`'IN'`) or dial code (`'+225'`).
- `initialValue`: a national number, or a full international number such as `'+447891234567'`, which also selects the country.
- `validator`: synchronous or asynchronous. Unless `disableLengthCheck` is `true`, the number must first contain only digits and match the country's length.
- `onChanged`: called on every edit, and when the user picks a different country.
- `languageCode`: language of country names in the picker, such as `'de'` or `'pt_BR'`.
- `countries`: limit the countries to choose from.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

Comment on Issue or Pull Request, asking @all-contributors to add a contributor:

```shell
@all-contributors please add @<username> for <contributions>
```

**\<contributions>**: See the [Emoji Key (Contribution Types Reference)](https://allcontributors.org/docs/en/emoji-key) for a list of valid contribution types.

## Maintainers
- [Vansh Goel](https://github.com/vanshg395/)
- [Alex N'Guessan](https://github.com/marcaureln/)

## Contributors
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://vansh.codes"><img src="https://avatars.githubusercontent.com/u/34906419?v=4?s=100" width="100px;" alt="Vansh Goel"/><br /><sub><b>Vansh Goel</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=vanshg395" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://twitter.com/Kunodayo_oboete"><img src="https://avatars.githubusercontent.com/u/23455702?v=4?s=100" width="100px;" alt="KNO3"/><br /><sub><b>KNO3</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=kno3a87" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.techarge.co.uk"><img src="https://avatars.githubusercontent.com/u/850493?v=4?s=100" width="100px;" alt="Ling Li"/><br /><sub><b>Ling Li</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=lingster" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://linkedin.com/in/anggaraputrapratama"><img src="https://avatars.githubusercontent.com/u/75307272?v=4?s=100" width="100px;" alt="Anggara Putra Pratama"/><br /><sub><b>Anggara Putra Pratama</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=anggaraputrapratama" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://geewax.org"><img src="https://avatars.githubusercontent.com/u/112928?v=4?s=100" width="100px;" alt="JJ Geewax"/><br /><sub><b>JJ Geewax</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=jgeewax" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/KevalPrajapati"><img src="https://avatars.githubusercontent.com/u/63007835?v=4?s=100" width="100px;" alt="Keval Prajapati"/><br /><sub><b>Keval Prajapati</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=KevalPrajapati" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://www.glaunay.fr"><img src="https://avatars.githubusercontent.com/u/18292489?v=4?s=100" width="100px;" alt="Guillaume Launay"/><br /><sub><b>Guillaume Launay</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=launay12u" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/2000calories"><img src="https://avatars.githubusercontent.com/u/25191098?v=4?s=100" width="100px;" alt="hans.huang"/><br /><sub><b>hans.huang</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=2000calories" title="Code">💻</a> <a href="https://github.com/vanshg395/intl_phone_field/commits?author=2000calories" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/The-Redhat"><img src="https://avatars.githubusercontent.com/u/33162310?v=4?s=100" width="100px;" alt="Gregor Weber"/><br /><sub><b>Gregor Weber</b></sub></a><br /><a href="https://github.com/vanshg395/intl_phone_field/commits?author=The-Redhat" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

## LICENSE

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
