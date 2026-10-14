## [4.0.0] - Release

Breaking:
- Built on `material_ui` and `cupertino_ui` instead of `package:flutter/material.dart`. Requires Flutter 3.47 / Dart 3.13, and apps must pass `material_ui` types (such as `InputDecoration`).
- `onChanged` is now also called when the user picks a different country.
- The `validator` now runs whenever the length check passes; before, its result was discarded for numbers of valid length. Non-digit input now fails the length check.
- The country picker can't be opened when the field is `readOnly`.
- `positionedPopup` attaches the picker to the field instead of the tap position.
- `CountryPickerDialog`: removed `filteredCountries`, `offset` and `alignment`, added `anchorRect`.
- `IntlPhoneFieldState`: removed `filteredCountries`, `number` and `validatorMessage`, added `selectedCountry` and `phoneNumber`.
- `isNumeric` now only accepts digits with an optional leading `+`.

Added:
- `CupertinoIntlPhoneField`, with a country picker in a Cupertino sheet (`CupertinoCountryPicker`, `CupertinoCountryPickerStyle`).
- `IntlPhoneField.adaptive`: the Cupertino field on iOS and macOS, the Material field elsewhere.
- The picker highlights the selected country, ranks name prefix matches first, and dismisses the keyboard on scroll.
- `languageCode` accepts any casing or separator (`pt-br`, `PT_BR`).

Fixed:
- `+44` numbers were detected as Guernsey (its region code was lost), which limited UK numbers to 6 digits. Restored the region codes of Guernsey, Jersey and Isle of Man.
- Numbers like `+1 876…` were detected as the first `+1` country. Detection now uses the longest dial code, and the main country for shared codes (US for `+1`, Russia for `+7`).
- `initialCountryCode` with a dial code (`'+225'`) was ignored.
- Crash with `AutovalidateMode.always` and no validator.
- The validator didn't run on `Form.validate()` until the user typed, async validator messages were never shown, and async validators delayed `onChanged`.
- The positioned popup could open off screen.
- The field only showed the new country after the picker's closing animation.
- Searching `+44` found nothing.
- Translations with a region or script (`pt_BR`, `zh_TW`, `sr-Cyrl`) were never used.
- An `initialValue` such as `9123456789` with `initialCountryCode: 'IN'` lost its leading `91`.
- `PhoneNumber.fromCompleteNumber` threw for unknown dial codes.
- `dropdownDecoration` with a `BorderRadiusDirectional` threw, and its color hid the tap ripple.
- The country button showed a ripple when disabled and couldn't be activated with the keyboard.
- `flagWidth` had no effect outside the web.
- Emoji flags don't render on Windows; image flags are used there.
- Phone number lengths of Puerto Rico, French Guiana, Guadeloupe, Martinique, Christmas Island, Cocos Islands, Finland, Åland Islands and Norfolk Island.

Performance:
- Country search no longer normalizes every name on each keystroke (about 300,000 string replacements); names are indexed once.
- The country list no longer uses `shrinkWrap`, and only the list rebuilds while searching.
- Flags have a fixed size, so rows don't shift while flag images load.
- Flag images (1 MB) are only bundled for web and Windows; other platforms use emoji flags.
- While the keyboard animates, the pickers no longer rebuild every visible row on each frame.

## [3.3.3] - Release
- Add: flag size option
## [3.3.2] - Release
- Add: isDense and ContentPadding Option
## [3.3.1] - Release
- fix: Positioned Popup made more accurate
- fix: Background transparent during normal Popup
## [3.3.0] - Release
- Added: Positioned Popup Option
## [3.2.2] - Release
- Fix: Country Flags not appearing
## [3.2.1] - Release
- Added: Option to set Popup Screen width

## [3.2.0] - Release

- Add `autofillHints` and disable posibility.
- Improve search (#243).
- Sort countries by name ascending (#243).
- Use flag emoji instead of images on mobile (#243).
- Add country name translations (#243).
- Fix `initialCountryCode` and add dial code support (58152d7cbefaf410c710d2e64680a9e4dd6015dd and 43362292198abc03ea1ce642ed5baa33b9fd8445).
- Add [flutter_lints](https://pub.dev/packages/flutter_lints) (6c19cbec745502e3865b9190cd1d399f7e909ddb).
- Update phone number length of several countries.

## [3.1.0] - Release

- **Breaking** `validator` function parameter type is [PhoneNumber] now instead of [String].
- Add `width` property to [PickerDialogStyle]
- Add `flagsButtonMargin` property
- Update phone number length of several countries.

## [3.0.1] - Release

- Fix [#146](https://github.com/vanshg395/intl_phone_field/issues/146)

## [3.0.0] - Release

- Add minimal country length.
- Update minimum and maximum length of phone numbers of several countries.
- Support country search by dial code.
- Move flag button to TextFormField's `prefixIcon` (always displayed and get rid of alignment issues).
- Add `dropdownTextStyle`, customize style use for the country dial code.
- Add `disableLengthCheck`, disable view minimum and maximum length check.
- Add a CountryPickerDialog widget and PickerDialogStyle (set of styles to allow the country search dialog customization).
- Add `flagsButtonPadding`, set custom padding around flag button.
- Add `invalidNumberMessage`, te message to be displayed on validation error.
- Add cursor customization options: `cursorColor`, `cursorHeight`, `cursorRadius`, `cursorWidth` and `showCursor`.
- Switch from country List of Maps to List of Country objects.
- `keyboardAppearance` use default `ThemeData.brightness`
- **Breaking** Rename `dropDownIcon` to `dropdownIcon` and `iconPosition` to `dropdownIconPosition`.
- **Breaking** Remove `autovalidate`.
- **Breaking** Add asynchronous validation.

## [2.1.0] - Added more parameters

- **Breaking** dropDownArrowIcon and dropDownArrowColor parameters are now replaced by dropDownIcon.
- Control autovalidateMode of text input added.
- showCountryFlag param added.
- textAlignVertical param added.
- Icon position feature added.
- Setting enabled to false disable the dropdown button too.
- Update maximum length of phone numbers of several countries.
- Minor fixes.

## [2.0.1] - Release

- Update maximum length of phone numbers of several countries.
- Add dropDownArrowIcon parameter.

## [2.0.0] - Null-Safe Compatibility.

- Package is now null-safe.
- onCountryChanged param added.
- Other Fixes.

## [1.4.2] - Improved Documentation.

- Color change for Dropdown Icon and Dialog is now added.

## [1.4.1] - Improved Documentation.

- More Documentation added for properties.

## [1.4.0] - Bug Fixes and improvements.

- Searchbar label text can be now set.
- Picker popup bug fixed.

## [1.3.0] - Added more parameters

- Initial Value can now be set.
- Phone field now returns ISO County code as well in onSaved, onChanged.
- Minor fixes.

## [1.2.0] - Added more common parameters

- Added some more necessary parameters available for a normal textfield.
- Minor fixes.

## [1.1.0] - Added Styling Elements

- Added styling of the country selection button.
- Added support for input formatters.
- Minor fixes.

## [1.0.1] - Release

- A Basic validator added.
- Updated README.

## [1.0.0] - Release

- A Custom Phone Input TextFormField.
