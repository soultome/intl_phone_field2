import 'package:cupertino_ui/cupertino_ui.dart';

// Defaults of CupertinoIntlPhoneField, shared with IntlPhoneField.adaptive.

const BorderSide _kDefaultBorderSide = BorderSide(
  color: CupertinoDynamicColor.withBrightness(color: Color(0x33000000), darkColor: Color(0x33FFFFFF)),
  width: 0.0,
);

/// Matches CupertinoTextField's default decoration.
const BoxDecoration kCupertinoPhoneFieldDecoration = BoxDecoration(
  color: CupertinoDynamicColor.withBrightness(color: CupertinoColors.white, darkColor: CupertinoColors.black),
  border: Border(
    top: _kDefaultBorderSide,
    bottom: _kDefaultBorderSide,
    left: _kDefaultBorderSide,
    right: _kDefaultBorderSide,
  ),
  borderRadius: BorderRadius.all(Radius.circular(5.0)),
);

const EdgeInsetsGeometry kCupertinoPhoneFieldPadding = EdgeInsets.all(7.0);

const Widget kCupertinoDropdownIcon = Icon(CupertinoIcons.chevron_down, size: 14);

const EdgeInsetsGeometry kCupertinoFlagsButtonPadding = EdgeInsetsDirectional.only(start: 4, end: 8);

const TextStyle kCupertinoPlaceholderStyle = TextStyle(
  fontWeight: FontWeight.w400,
  color: CupertinoColors.placeholderText,
);
