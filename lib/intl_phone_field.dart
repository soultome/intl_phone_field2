library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl_phone_field2/country_picker_dialog.dart';
import 'package:intl_phone_field2/cupertino_intl_phone_field.dart';
import 'package:intl_phone_field2/src/country_flag.dart';
import 'package:intl_phone_field2/src/country_utils.dart';
import 'package:intl_phone_field2/src/cupertino_defaults.dart';
import 'package:intl_phone_field2/src/phone_validation.dart';
import 'package:material_ui/material_ui.dart';

import './countries.dart';
import './phone_number.dart';

export 'package:intl_phone_field2/country_picker_dialog.dart' show PickerDialogStyle;
export 'package:intl_phone_field2/cupertino_country_picker.dart' show CupertinoCountryPickerStyle;
export 'package:intl_phone_field2/src/icon_position.dart';

/// A Material text field to enter a phone number, with a country code picker.
///
/// Use [IntlPhoneField.adaptive] to get a [CupertinoIntlPhoneField] on iOS
/// and macOS instead.
class IntlPhoneField extends StatefulWidget {
  /// Whether to hide the text being edited (e.g., for passwords).
  final bool obscureText;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// How the text should be aligned vertically.
  final TextAlignVertical? textAlignVertical;
  final VoidCallback? onTap;

  /// {@macro flutter.widgets.editableText.readOnly}
  final bool readOnly;
  final FormFieldSetter<PhoneNumber>? onSaved;

  /// {@macro flutter.widgets.editableText.onChanged}
  ///
  /// See also:
  ///
  ///  * [inputFormatters], which are called before [onChanged]
  ///    runs and can validate and change ("format") the input value.
  ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]:
  ///    which are more specialized input change notifications.
  final ValueChanged<PhoneNumber>? onChanged;

  final ValueChanged<Country>? onCountryChanged;

  /// An optional method that validates an input. Returns an error string to display if the input is invalid, or null otherwise.
  ///
  /// A [PhoneNumber] is passed to the validator as argument.
  /// The validator can handle asynchronous validation when declared as a [Future].
  /// Or run synchronously when declared as a [Function].
  ///
  /// Unless [disableLengthCheck] is `true`, a non-empty number must first contain
  /// only digits and be between the selected country's min and max length;
  /// otherwise [invalidNumberMessage] is shown and your validator is not called.
  ///
  /// An asynchronous validator runs once per distinct number. Until it completes,
  /// the previous message stays visible; the field then validates again.
  final FutureOr<String?> Function(PhoneNumber?)? validator;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType keyboardType;

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  ///
  /// When a controller is provided, [initialValue] is ignored: set the national
  /// number on the controller and the country with [initialCountryCode].
  final TextEditingController? controller;

  /// Defines the keyboard focus for this widget.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a
  /// [StatefulWidget] parent. See [FocusNode] for more information.
  ///
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(myFocusNode);
  /// ```
  ///
  /// This happens automatically when the widget is tapped.
  ///
  /// To be notified when the widget gains or loses the focus, add a listener
  /// to the [focusNode]:
  ///
  /// ```dart
  /// focusNode.addListener(() { print(myFocusNode.hasFocus); });
  /// ```
  ///
  /// If null, this widget will create its own [FocusNode].
  ///
  /// ## Keyboard
  ///
  /// Requesting the focus will typically cause the keyboard to be shown
  /// if it's not showing already.
  ///
  /// On Android, the user can hide the keyboard - without changing the focus -
  /// with the system back button. They can restore the keyboard's visibility
  /// by tapping on a text field.  The user might hide the keyboard and
  /// switch to a physical keyboard, or they might just need to get it
  /// out of the way for a moment, to expose something it's
  /// obscuring. In this case requesting the focus again will not
  /// cause the focus to change, and will not make the keyboard visible.
  ///
  /// This widget builds an [EditableText] and will ensure that the keyboard is
  /// showing when it is tapped by calling [EditableTextState.requestKeyboard()].
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.editableText.onSubmitted}
  ///
  /// See also:
  ///
  ///  * [EditableText.onSubmitted] for an example of how to handle moving to
  ///    the next/previous field when using [TextInputAction.next] and
  ///    [TextInputAction.previous] for [textInputAction].
  final void Function(String)? onSubmitted;

  /// If false the widget is "disabled": it ignores taps, the [TextFormField]'s
  /// [decoration] is rendered in grey,
  /// [decoration]'s [InputDecoration.counterText] is set to `""`,
  /// and the drop down icon is hidden no matter [showDropdownIcon] value.
  ///
  /// If non-null this property overrides the [decoration]'s
  /// [Decoration.enabled] property.
  final bool enabled;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [ThemeData.brightness].
  final Brightness? keyboardAppearance;

  /// Initial Value for the field.
  /// This property can be used to pre-fill the field.
  ///
  /// A full international number such as `+447891234567` also selects its
  /// country, using the longest matching dial code.
  final String? initialValue;

  /// Language used for country names in the picker, such as `en`, `de` or
  /// `pt_BR`. Falls back to English when no translation exists.
  final String languageCode;

  /// 2 letter ISO Code or country dial code.
  ///
  /// ```dart
  /// initialCountryCode: 'IN', // India
  /// initialCountryCode: '+225', // Côte d'Ivoire
  /// ```
  final String? initialCountryCode;

  /// List of Country to display see countries.dart for format
  final List<Country>? countries;

  /// The decoration to show around the text field.
  ///
  /// By default, draws a horizontal line under the text field but can be
  /// configured to show an icon, label, hint text, and error text.
  ///
  /// Specify null to remove the decoration entirely (including the
  /// extra padding introduced by the decoration to save space for the labels).
  final InputDecoration decoration;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to the `subtitle1` text style from the current [Theme].
  final TextStyle? style;

  /// Disable view Min/Max Length check
  final bool disableLengthCheck;

  /// Won't work if [enabled] is set to `false`.
  ///
  /// The country picker can't be opened when [enabled] is `false` or
  /// [readOnly] is `true`.
  final bool showDropdownIcon;

  final BoxDecoration dropdownDecoration;

  /// The style use for the country dial code.
  final TextStyle? dropdownTextStyle;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter>? inputFormatters;

  /// The text that describes the search input field.
  ///
  /// With [IntlPhoneField.adaptive], it is also the placeholder of the
  /// Cupertino picker's search field.
  ///
  /// When the input field is empty and unfocused, the label is displayed on top of the input field (i.e., at the same location on the screen where text may be entered in the input field).
  /// When the input field receives focus (or if the field is non-empty), the label moves above (i.e., vertically adjacent to) the input field.
  final String searchText;

  /// Position of an icon [leading, trailing]
  final IconPosition dropdownIconPosition;

  /// Icon of the drop down button.
  ///
  /// Default is [Icon(Icons.arrow_drop_down)]
  final Icon dropdownIcon;

  /// Whether this text field should focus itself if nothing else is already focused.
  final bool autofocus;

  /// Autovalidate mode for text form field.
  ///
  /// If [AutovalidateMode.onUserInteraction], this FormField will only auto-validate after its content changes.
  /// If [AutovalidateMode.always], it will auto-validate even without user interaction.
  /// If [AutovalidateMode.disabled], auto-validation will be disabled.
  ///
  /// Defaults to [AutovalidateMode.onUserInteraction].
  final AutovalidateMode? autovalidateMode;

  /// Whether to show or hide country flag.
  ///
  /// Default value is `true`.
  final bool showCountryFlag;

  /// Message to be displayed on autoValidate error
  ///
  /// Default value is `Invalid Mobile Number`.
  final String? invalidNumberMessage;

  /// The color of the cursor.
  final Color? cursorColor;

  /// How tall the cursor will be.
  final double? cursorHeight;

  /// How rounded the corners of the cursor should be.
  final Radius? cursorRadius;

  /// How thick the cursor will be.
  final double cursorWidth;

  /// Whether to show cursor.
  final bool? showCursor;

  /// The padding of the Flags Button.
  ///
  /// The amount of insets that are applied to the Flags Button.
  ///
  /// If unset, defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry flagsButtonPadding;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Optional set of styles to allow for customizing the country search
  /// & pick dialog
  final PickerDialogStyle? pickerDialogStyle;

  /// The margin of the country selector button.
  ///
  /// The amount of space to surround the country selector button.
  ///
  /// If unset, defaults to [EdgeInsets.zero].
  final EdgeInsets flagsButtonMargin;

  //enable the autofill hint for phone number
  final bool disableAutoFillHints;

  /// The width of the country picker. Overrides [PickerDialogStyle.width].
  ///
  /// When [positionedPopup] is `true`, defaults to the width of the field.
  final double? popupWidth;

  /// Shows the country picker as a dropdown attached to the field instead of a
  /// centered dialog. It opens below the field, or above it when there is more
  /// room there, and always stays on screen.
  final bool positionedPopup;

  /// Overrides [InputDecoration.contentPadding] of [decoration].
  final EdgeInsets? textFieldPadding;

  /// Overrides [InputDecoration.isDense] of [decoration].
  final bool? textFieldIsDense;

  /// Width of the country flag. Emoji flags are scaled proportionally.
  final double flagWidth;

  /// Decoration of the field on iOS and macOS, with [IntlPhoneField.adaptive].
  /// Defaults to a rounded border; `null` draws no border.
  final BoxDecoration? cupertinoDecoration;

  /// Styles the country picker sheet on iOS and macOS, with
  /// [IntlPhoneField.adaptive].
  final CupertinoCountryPickerStyle? cupertinoPickerStyle;

  final bool _adaptive;

  // The values passed to IntlPhoneField.adaptive, where null means the
  // platform's default.
  final Icon? _adaptiveDropdownIcon;
  final IconPosition? _adaptiveDropdownIconPosition;
  final EdgeInsetsGeometry? _adaptiveFlagsButtonPadding;

  const IntlPhoneField({
    super.key,
    this.popupWidth,
    this.flagWidth = 32,
    this.textFieldPadding,
    this.textFieldIsDense,
    this.positionedPopup = false,
    this.initialCountryCode,
    this.languageCode = 'en',
    this.disableAutoFillHints = false,
    this.obscureText = false,
    this.textAlign = TextAlign.left,
    this.textAlignVertical,
    this.onTap,
    this.readOnly = false,
    this.initialValue,
    this.keyboardType = TextInputType.phone,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.dropdownTextStyle,
    this.onSubmitted,
    this.validator,
    this.onChanged,
    this.countries,
    this.onCountryChanged,
    this.onSaved,
    this.showDropdownIcon = true,
    this.dropdownDecoration = const BoxDecoration(),
    this.inputFormatters,
    this.enabled = true,
    this.keyboardAppearance,
    @Deprecated('Use searchFieldInputDecoration of PickerDialogStyle instead') this.searchText = 'Search country',
    this.dropdownIconPosition = IconPosition.leading,
    this.dropdownIcon = const Icon(Icons.arrow_drop_down),
    this.autofocus = false,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.showCountryFlag = true,
    this.cursorColor,
    this.disableLengthCheck = false,
    this.flagsButtonPadding = EdgeInsets.zero,
    this.invalidNumberMessage = 'Invalid Mobile Number',
    this.cursorHeight,
    this.cursorRadius = Radius.zero,
    this.cursorWidth = 2.0,
    this.showCursor = true,
    this.pickerDialogStyle,
    this.flagsButtonMargin = EdgeInsets.zero,
  }) : cupertinoDecoration = null,
       cupertinoPickerStyle = null,
       _adaptive = false,
       _adaptiveDropdownIcon = null,
       _adaptiveDropdownIconPosition = null,
       _adaptiveFlagsButtonPadding = null;

  /// Creates a phone field that follows the platform's design: a
  /// [CupertinoIntlPhoneField] with a sheet picker on iOS and macOS, and a
  /// Material field with a dialog picker everywhere else.
  ///
  /// The platform is read from [ThemeData.platform], like Flutter's own
  /// adaptive widgets such as [Switch.adaptive].
  ///
  /// On iOS and macOS:
  ///  * [decoration]'s `hintText` (or else `labelText`) is the placeholder,
  ///    styled by its `hintStyle`; its `errorStyle` styles validation
  ///    messages. [cupertinoDecoration] draws the field.
  ///  * [cupertinoPickerStyle] styles the country picker sheet.
  ///  * Material-only options are ignored: [positionedPopup], [popupWidth],
  ///    [pickerDialogStyle], [dropdownDecoration], [flagsButtonMargin] and
  ///    [textFieldIsDense].
  ///
  /// When null, [dropdownIcon], [dropdownIconPosition], [flagsButtonPadding]
  /// and [cursorRadius] follow each platform's style.
  const IntlPhoneField.adaptive({
    super.key,
    this.popupWidth,
    this.flagWidth = 32,
    this.textFieldPadding,
    this.textFieldIsDense,
    this.positionedPopup = false,
    this.initialCountryCode,
    this.languageCode = 'en',
    this.disableAutoFillHints = false,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.onTap,
    this.readOnly = false,
    this.initialValue,
    this.keyboardType = TextInputType.phone,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.dropdownTextStyle,
    this.onSubmitted,
    this.validator,
    this.onChanged,
    this.countries,
    this.onCountryChanged,
    this.onSaved,
    this.showDropdownIcon = true,
    this.dropdownDecoration = const BoxDecoration(),
    this.inputFormatters,
    this.enabled = true,
    this.keyboardAppearance,
    this.searchText = 'Search country',
    IconPosition? dropdownIconPosition,
    Icon? dropdownIcon,
    this.autofocus = false,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.showCountryFlag = true,
    this.cursorColor,
    this.disableLengthCheck = false,
    EdgeInsetsGeometry? flagsButtonPadding,
    this.invalidNumberMessage = 'Invalid Mobile Number',
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.showCursor = true,
    this.pickerDialogStyle,
    this.flagsButtonMargin = EdgeInsets.zero,
    this.cupertinoDecoration = kCupertinoPhoneFieldDecoration,
    this.cupertinoPickerStyle,
  }) : dropdownIcon = dropdownIcon ?? const Icon(Icons.arrow_drop_down),
       dropdownIconPosition = dropdownIconPosition ?? IconPosition.leading,
       flagsButtonPadding = flagsButtonPadding ?? EdgeInsets.zero,
       _adaptive = true,
       _adaptiveDropdownIcon = dropdownIcon,
       _adaptiveDropdownIconPosition = dropdownIconPosition,
       _adaptiveFlagsButtonPadding = flagsButtonPadding;

  @override
  IntlPhoneFieldState createState() => IntlPhoneFieldState();
}

class IntlPhoneFieldState extends State<IntlPhoneField> {
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey<FormFieldState<String>>();
  late final GlobalKey<CupertinoIntlPhoneFieldState> _cupertinoKey = GlobalKey<CupertinoIntlPhoneFieldState>();
  late final PhoneFieldValidation _validation = PhoneFieldValidation(onAsyncResult: _revalidate);
  late List<Country> _countryList;
  late Country _selectedCountry;
  late String _initialNumber;

  /// The currently selected country.
  Country get selectedCountry => _cupertinoKey.currentState?.selectedCountry ?? _selectedCountry;

  /// The number currently entered, with the selected country.
  PhoneNumber get phoneNumber =>
      _cupertinoKey.currentState?.phoneNumber ?? phoneNumberFor(_selectedCountry, _currentNumber);

  String get _currentNumber => _fieldKey.currentState?.value ?? widget.controller?.text ?? _initialNumber;

  bool get _canPickCountry => widget.enabled && !widget.readOnly;

  bool get _useCupertino =>
      widget._adaptive &&
      switch (Theme.of(context).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => true,
        _ => false,
      };

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
  void didUpdateWidget(IntlPhoneField oldWidget) {
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

  void _onCountrySelected(Country country) {
    if (!mounted) return;
    final changed = !isSameCountry(country, _selectedCountry);
    setState(() => _selectedCountry = country);
    widget.onCountryChanged?.call(country);
    if (changed) widget.onChanged?.call(phoneNumber);
  }

  /// The field's bounds in the coordinate space of the picker's overlay.
  Rect? _anchorRect() {
    final field = _fieldKey.currentContext?.findRenderObject();
    final overlay = Navigator.of(context).overlay?.context.findRenderObject();
    if (field is! RenderBox || overlay is! RenderBox || !field.hasSize) return null;
    return MatrixUtils.transformRect(field.getTransformTo(overlay), Offset.zero & field.size);
  }

  Future<void> _openCountryPicker() async {
    final anchorRect = widget.positionedPopup ? _anchorRect() : null;
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      useSafeArea: anchorRect == null,
      barrierColor: anchorRect != null ? Colors.transparent : Colors.black45,
      builder: (context) => CountryPickerDialog(
        anchorRect: anchorRect,
        popupWidth: widget.popupWidth,
        languageCode: widget.languageCode,
        style: widget.pickerDialogStyle,
        // ignore: deprecated_member_use_from_same_package
        searchText: widget.searchText,
        countryList: _countryList,
        selectedCountry: _selectedCountry,
        onCountryChanged: _onCountrySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useCupertino) return _buildCupertinoField();
    return TextFormField(
      key: _fieldKey,
      initialValue: (widget.controller == null) ? _initialNumber : null,
      autofillHints: widget.disableAutoFillHints ? null : const [AutofillHints.telephoneNumberNational],
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      cursorColor: widget.cursorColor,
      onTap: widget.onTap,
      controller: widget.controller,
      focusNode: widget.focusNode,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorWidth: widget.cursorWidth,
      showCursor: widget.showCursor,
      onFieldSubmitted: widget.onSubmitted,
      decoration: widget.decoration.copyWith(
        isDense: widget.textFieldIsDense,
        contentPadding: widget.textFieldPadding,
        prefixIcon: _buildFlagsButton(),
        counterText: !widget.enabled ? '' : null,
      ),
      style: widget.style,
      onSaved: (value) => widget.onSaved?.call(phoneNumberFor(_selectedCountry, value ?? '')),
      onChanged: (value) => widget.onChanged?.call(phoneNumberFor(_selectedCountry, value)),
      validator: _validate,
      maxLength: widget.disableLengthCheck ? null : _selectedCountry.maxLength,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      keyboardAppearance: widget.keyboardAppearance,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      autovalidateMode: widget.autovalidateMode,
    );
  }

  Widget _buildCupertinoField() {
    final decoration = widget.decoration;
    return CupertinoIntlPhoneField(
      key: _cupertinoKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      initialCountryCode: widget.initialCountryCode,
      countries: widget.countries,
      languageCode: widget.languageCode,
      placeholder: decoration.hintText ?? decoration.labelText,
      placeholderStyle: decoration.hintStyle,
      style: widget.style,
      decoration: widget.cupertinoDecoration,
      padding: widget.textFieldPadding ?? kCupertinoPhoneFieldPadding,
      onChanged: widget.onChanged,
      onCountryChanged: (country) {
        _selectedCountry = country;
        widget.onCountryChanged?.call(country);
      },
      onSubmitted: widget.onSubmitted,
      onSaved: widget.onSaved,
      onTap: widget.onTap,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      disableLengthCheck: widget.disableLengthCheck,
      invalidNumberMessage: widget.invalidNumberMessage,
      errorStyle: decoration.errorStyle,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      keyboardAppearance: widget.keyboardAppearance,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      cursorColor: widget.cursorColor,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius ?? const Radius.circular(2.0),
      showCursor: widget.showCursor,
      disableAutoFillHints: widget.disableAutoFillHints,
      showCountryFlag: widget.showCountryFlag,
      flagWidth: widget.flagWidth,
      showDropdownIcon: widget.showDropdownIcon,
      dropdownIcon: widget._adaptiveDropdownIcon ?? kCupertinoDropdownIcon,
      dropdownIconPosition: widget._adaptiveDropdownIconPosition ?? IconPosition.trailing,
      dropdownTextStyle: widget.dropdownTextStyle,
      flagsButtonPadding: widget._adaptiveFlagsButtonPadding ?? kCupertinoFlagsButtonPadding,
      // ignore: deprecated_member_use_from_same_package
      searchText: widget.searchText,
      pickerStyle: widget.cupertinoPickerStyle,
    );
  }

  Widget _buildFlagsButton() {
    final showIcon = widget.enabled && widget.showDropdownIcon;
    final borderRadius = widget.dropdownDecoration.borderRadius?.resolve(Directionality.of(context));
    return Padding(
      padding: widget.flagsButtonMargin,
      child: DecoratedBox(
        decoration: widget.dropdownDecoration,
        // Splashes paint on the nearest Material, so give the button its own
        // above the decoration; otherwise a decoration color would hide them.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: _canPickCountry ? _openCountryPicker : null,
            child: Padding(
              padding: widget.flagsButtonPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(width: 4),
                  if (showIcon && widget.dropdownIconPosition == IconPosition.leading) ...[
                    widget.dropdownIcon,
                    const SizedBox(width: 4),
                  ],
                  if (widget.showCountryFlag) ...[
                    CountryFlag(country: _selectedCountry, width: widget.flagWidth, gaplessPlayback: true),
                    const SizedBox(width: 8),
                  ],
                  Text('+${_selectedCountry.displayCC}', style: widget.dropdownTextStyle),
                  if (showIcon && widget.dropdownIconPosition == IconPosition.trailing) ...[
                    const SizedBox(width: 4),
                    widget.dropdownIcon,
                  ],
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
