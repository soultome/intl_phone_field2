/// An iOS-style international phone number field, built on `cupertino_ui`.
library;

import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/cupertino_country_picker.dart';
import 'package:intl_phone_field2/phone_number.dart';
import 'package:intl_phone_field2/src/country_flag.dart';
import 'package:intl_phone_field2/src/country_utils.dart';
import 'package:intl_phone_field2/src/cupertino_defaults.dart';
import 'package:intl_phone_field2/src/icon_position.dart';
import 'package:intl_phone_field2/src/phone_validation.dart';

export 'package:intl_phone_field2/cupertino_country_picker.dart' show CupertinoCountryPickerStyle;
export 'package:intl_phone_field2/src/icon_position.dart';

/// An iOS-style text field to enter a phone number, with a country code
/// picker shown in a Cupertino sheet.
///
/// Works inside a [Form] like a `TextFormField`: it supports [validator],
/// [onSaved], [autovalidateMode] and `FormState.reset`.
///
/// ```dart
/// CupertinoIntlPhoneField(
///   initialCountryCode: 'IN',
///   placeholder: 'Phone number',
///   onChanged: (phone) => print(phone.completeNumber),
/// )
/// ```
class CupertinoIntlPhoneField extends StatefulWidget {
  /// Controls the text being edited (the national number, without the country
  /// code). When provided, [initialValue] is ignored.
  final TextEditingController? controller;

  final FocusNode? focusNode;

  /// Initial number. A full international number such as `+447891234567`
  /// also selects its country.
  final String? initialValue;

  /// 2 letter ISO code (`'IN'`) or dial code (`'+225'`) of the initially
  /// selected country. Defaults to `US`.
  final String? initialCountryCode;

  /// Countries to choose from. Defaults to all countries.
  final List<Country>? countries;

  /// Language used for country names in the picker, such as `en`, `de` or
  /// `pt_BR`.
  final String languageCode;

  final String? placeholder;
  final TextStyle? placeholderStyle;
  final TextStyle? style;

  /// Decoration around the field. Defaults to [CupertinoTextField]'s rounded
  /// border; pass `null` for a borderless field, for example inside a
  /// `CupertinoFormSection`.
  final BoxDecoration? decoration;

  final EdgeInsetsGeometry padding;

  final ValueChanged<PhoneNumber>? onChanged;

  /// Called when the user picks a country. [onChanged] is also called if the
  /// country is different from the previous one.
  final ValueChanged<Country>? onCountryChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldSetter<PhoneNumber>? onSaved;
  final GestureTapCallback? onTap;

  /// Validates the number. Can be synchronous or return a [Future].
  ///
  /// Unless [disableLengthCheck] is `true`, a non-empty number must first contain
  /// only digits and match the selected country's length; otherwise
  /// [invalidNumberMessage] is shown and this validator is not called.
  final FutureOr<String?> Function(PhoneNumber?)? validator;
  final AutovalidateMode autovalidateMode;
  final bool disableLengthCheck;
  final String? invalidNumberMessage;

  /// Style of the validation message. Defaults to 13pt
  /// [CupertinoColors.destructiveRed].
  final TextStyle? errorStyle;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Brightness? keyboardAppearance;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final Color? cursorColor;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius cursorRadius;
  final bool? showCursor;
  final bool disableAutoFillHints;

  final bool showCountryFlag;
  final double flagWidth;

  /// Hidden when [enabled] is `false`.
  final bool showDropdownIcon;
  final Widget dropdownIcon;
  final IconPosition dropdownIconPosition;

  /// Style of the dial code. Defaults to the field's text style.
  final TextStyle? dropdownTextStyle;
  final EdgeInsetsGeometry flagsButtonPadding;

  /// Whether to draw a thin line between the country code and the number.
  final bool showSeparator;

  /// Placeholder of the picker's search field.
  final String searchText;
  final CupertinoCountryPickerStyle? pickerStyle;

  const CupertinoIntlPhoneField({
    super.key,
    this.controller,
    this.focusNode,
    this.initialValue,
    this.initialCountryCode,
    this.countries,
    this.languageCode = 'en',
    this.placeholder,
    this.placeholderStyle,
    this.style,
    this.decoration = kCupertinoPhoneFieldDecoration,
    this.padding = kCupertinoPhoneFieldPadding,
    this.onChanged,
    this.onCountryChanged,
    this.onSubmitted,
    this.onSaved,
    this.onTap,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.disableLengthCheck = false,
    this.invalidNumberMessage = 'Invalid Mobile Number',
    this.errorStyle,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.phone,
    this.textInputAction,
    this.inputFormatters,
    this.keyboardAppearance,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.cursorColor,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2.0),
    this.showCursor,
    this.disableAutoFillHints = false,
    this.showCountryFlag = true,
    this.flagWidth = 32,
    this.showDropdownIcon = true,
    this.dropdownIcon = kCupertinoDropdownIcon,
    this.dropdownIconPosition = IconPosition.trailing,
    this.dropdownTextStyle,
    this.flagsButtonPadding = kCupertinoFlagsButtonPadding,
    this.showSeparator = true,
    this.searchText = 'Search country',
    this.pickerStyle,
  });

  @override
  CupertinoIntlPhoneFieldState createState() => CupertinoIntlPhoneFieldState();
}

class CupertinoIntlPhoneFieldState extends State<CupertinoIntlPhoneField> {
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey<FormFieldState<String>>();
  late final PhoneFieldValidation _validation = PhoneFieldValidation(onAsyncResult: _revalidate);
  late List<Country> _countryList;
  late Country _selectedCountry;
  late String _initialNumber;

  /// The currently selected country.
  Country get selectedCountry => _selectedCountry;

  /// The number currently entered, with the selected country.
  PhoneNumber get phoneNumber => phoneNumberFor(_selectedCountry, _currentNumber);

  String get _currentNumber => _fieldKey.currentState?.value ?? widget.controller?.text ?? _initialNumber;

  bool get _canPickCountry => widget.enabled && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _countryList = widget.countries ?? countries;
    final initial = parseInitialPhoneNumber(
      countries: _countryList,
      initialCountryCode: widget.initialCountryCode,
      initialValue: widget.initialValue,
    );
    _selectedCountry = initial.country;
    _initialNumber = initial.number;
  }

  @override
  void didUpdateWidget(CupertinoIntlPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countries != oldWidget.countries) {
      _countryList = widget.countries ?? countries;
    }
  }

  @override
  void dispose() {
    _validation.dispose();
    super.dispose();
  }

  void _revalidate() {
    if (mounted) _fieldKey.currentState?.validate();
  }

  String? _validate(String? value) => _validation.validate(
    value: value,
    country: _selectedCountry,
    disableLengthCheck: widget.disableLengthCheck,
    invalidNumberMessage: widget.invalidNumberMessage,
    validator: widget.validator,
  );

  void _handleChanged(String value) => widget.onChanged?.call(phoneNumberFor(_selectedCountry, value));

  void _onCountrySelected(Country country) {
    if (!mounted) return;
    final changed = !isSameCountry(country, _selectedCountry);
    setState(() => _selectedCountry = country);
    widget.onCountryChanged?.call(country);
    if (changed) widget.onChanged?.call(phoneNumber);
  }

  Future<void> _openCountryPicker() async {
    await showCupertinoSheet<void>(
      context: context,
      showDragHandle: widget.pickerStyle?.showDragHandle ?? true,
      scrollableBuilder: (context, scrollController) => CupertinoCountryPicker(
        scrollController: scrollController,
        countryList: _countryList,
        selectedCountry: _selectedCountry,
        languageCode: widget.languageCode,
        searchText: widget.searchText,
        style: widget.pickerStyle,
        onCountryChanged: _onCountrySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Built here rather than in fieldBuilder, which runs on every keystroke.
    final countryButton = _buildCountryButton(context);
    return _CupertinoPhoneFormField(
      key: _fieldKey,
      controller: widget.controller,
      initialValue: _initialNumber,
      validator: _validate,
      onSaved: (value) => widget.onSaved?.call(phoneNumberFor(_selectedCountry, value ?? '')),
      onTextReset: _handleChanged,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      fieldBuilder: (field, controller) {
        final errorText = field.errorText;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CupertinoTextField(
              controller: controller,
              focusNode: widget.focusNode,
              decoration: widget.decoration,
              padding: widget.padding,
              placeholder: widget.placeholder,
              placeholderStyle: widget.placeholderStyle ?? kCupertinoPlaceholderStyle,
              style: widget.style,
              prefix: countryButton,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              keyboardAppearance: widget.keyboardAppearance,
              textAlign: widget.textAlign,
              textAlignVertical: widget.textAlignVertical,
              cursorColor: widget.cursorColor,
              cursorWidth: widget.cursorWidth,
              cursorHeight: widget.cursorHeight,
              cursorRadius: widget.cursorRadius,
              showCursor: widget.showCursor,
              autofillHints: widget.disableAutoFillHints ? null : const [AutofillHints.telephoneNumberNational],
              maxLength: widget.disableLengthCheck ? null : _selectedCountry.maxLength,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              onTap: widget.onTap,
              onSubmitted: widget.onSubmitted,
              onChanged: (value) {
                field.didChange(value);
                _handleChanged(value);
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional.topStart,
              child: errorText == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(start: 6, top: 6),
                      child: Text(
                        errorText,
                        style:
                            widget.errorStyle ??
                            TextStyle(fontSize: 13, color: CupertinoColors.destructiveRed.resolveFrom(context)),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryButton(BuildContext context) {
    final showIcon = widget.enabled && widget.showDropdownIcon;
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle
        .merge(widget.style)
        .merge(widget.dropdownTextStyle);
    final icon = IconTheme.merge(
      data: IconThemeData(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
      child: widget.dropdownIcon,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CupertinoButton(
          padding: widget.flagsButtonPadding,
          minimumSize: Size.zero,
          pressedOpacity: 0.5,
          onPressed: _canPickCountry ? _openCountryPicker : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showIcon && widget.dropdownIconPosition == IconPosition.leading) ...[icon, const SizedBox(width: 4)],
              if (widget.showCountryFlag) ...[
                CountryFlag(country: _selectedCountry, width: widget.flagWidth, gaplessPlayback: true),
                const SizedBox(width: 6),
              ],
              Text(
                '+${_selectedCountry.displayCC}',
                style: widget.enabled
                    ? textStyle
                    : textStyle.copyWith(color: CupertinoColors.placeholderText.resolveFrom(context)),
              ),
              if (showIcon && widget.dropdownIconPosition == IconPosition.trailing) ...[const SizedBox(width: 4), icon],
            ],
          ),
        ),
        if (widget.showSeparator)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: SizedBox(
              width: 1 / MediaQuery.devicePixelRatioOf(context),
              height: 20,
              child: ColoredBox(color: CupertinoColors.separator.resolveFrom(context)),
            ),
          ),
      ],
    );
  }
}

/// A [FormField] that owns the field's [TextEditingController] (unless one is
/// provided) and keeps it in sync with the form value, like `TextFormField`.
class _CupertinoPhoneFormField extends FormField<String> {
  _CupertinoPhoneFormField({
    super.key,
    required this.controller,
    required String initialValue,
    required this.onTextReset,
    required Widget Function(FormFieldState<String> field, TextEditingController controller) fieldBuilder,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
  }) : super(
         initialValue: controller?.text ?? initialValue,
         builder: (field) => fieldBuilder(field, (field as _CupertinoPhoneFormFieldState)._effectiveController),
       );

  final TextEditingController? controller;
  final ValueChanged<String> onTextReset;

  @override
  FormFieldState<String> createState() => _CupertinoPhoneFormFieldState();
}

class _CupertinoPhoneFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;

  _CupertinoPhoneFormField get _field => widget as _CupertinoPhoneFormField;

  TextEditingController get _effectiveController => _field.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    if (_field.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      _field.controller!.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(_CupertinoPhoneFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_field.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      _field.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && _field.controller == null) {
        _controller = TextEditingController.fromValue(oldWidget.controller!.value);
      }
      if (_field.controller != null) {
        setValue(_field.controller!.text);
        if (oldWidget.controller == null) {
          _controller?.dispose();
          _controller = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _field.controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (value != null && _effectiveController.text != value) {
      _effectiveController.text = value;
    }
  }

  @override
  void reset() {
    // Update the controller first so _handleControllerChanged ignores it.
    _effectiveController.text = widget.initialValue ?? '';
    super.reset();
    _field.onTextReset(_effectiveController.text);
  }

  void _handleControllerChanged() {
    // Picks up changes made to a provided controller from outside this field.
    if (_effectiveController.text != value) didChange(_effectiveController.text);
  }
}
