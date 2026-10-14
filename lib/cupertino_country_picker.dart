import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/src/country_flag.dart';
import 'package:intl_phone_field2/src/country_utils.dart';

/// Optional styles for [CupertinoCountryPicker].
class CupertinoCountryPickerStyle {
  /// Background of the sheet. Defaults to [CupertinoColors.systemBackground].
  final Color? backgroundColor;

  final TextStyle? countryNameStyle;

  /// Style of the dial code shown at the end of each row.
  final TextStyle? countryCodeStyle;

  /// Color of the checkmark next to the selected country. Defaults to the
  /// theme's primary color.
  final Color? checkmarkColor;

  /// Padding around the search field.
  final EdgeInsetsGeometry? searchFieldPadding;

  final EdgeInsetsGeometry? listTilePadding;

  /// Whether to draw separators between rows.
  final bool showDividers;

  /// Width of the flag in each row.
  final double flagWidth;

  /// Whether the sheet shows a drag handle at the top.
  final bool showDragHandle;

  const CupertinoCountryPickerStyle({
    this.backgroundColor,
    this.countryNameStyle,
    this.countryCodeStyle,
    this.checkmarkColor,
    this.searchFieldPadding,
    this.listTilePadding,
    this.showDividers = true,
    this.flagWidth = 28,
    this.showDragHandle = true,
  });
}

/// An iOS-style list to search for and pick a country, meant to be shown in a
/// sheet with [showCupertinoSheet].
///
/// Pass the sheet's [ScrollController] as [scrollController] so dragging the
/// list down at its top dismisses the sheet.
class CupertinoCountryPicker extends StatefulWidget {
  final List<Country> countryList;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final String languageCode;

  /// Placeholder of the search field.
  final String searchText;
  final CupertinoCountryPickerStyle? style;
  final ScrollController? scrollController;

  const CupertinoCountryPicker({
    super.key,
    required this.countryList,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.languageCode = 'en',
    this.searchText = 'Search country',
    this.style,
    this.scrollController,
  });

  @override
  State<CupertinoCountryPicker> createState() => _CupertinoCountryPickerState();
}

class _CupertinoCountryPickerState extends State<CupertinoCountryPicker> {
  late CountryFilter _filter;
  late final ValueNotifier<List<Country>> _results;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = CountryFilter(widget.countryList, widget.languageCode);
    _results = ValueNotifier<List<Country>>(_filter.all);
  }

  @override
  void didUpdateWidget(CupertinoCountryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countryList != oldWidget.countryList || widget.languageCode != oldWidget.languageCode) {
      _filter = CountryFilter(widget.countryList, widget.languageCode);
      _results.value = _filter.filter(_query);
    }
  }

  @override
  void dispose() {
    _results.dispose();
    super.dispose();
  }

  void _search(String query) {
    _query = query;
    _results.value = _filter.filter(query);
  }

  void _select(Country country) {
    widget.onCountryChanged(country);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final flagWidth = style?.flagWidth ?? 28;
    final cancelLabel =
        Localizations.of<CupertinoLocalizations>(context, CupertinoLocalizations)?.cancelButtonLabel ?? 'Cancel';
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final separatorIndent = flagWidth + 32;

    final searchRow = Row(
      children: <Widget>[
        Expanded(
          child: CupertinoSearchTextField(
            placeholder: widget.searchText,
            onChanged: _search,
            onSubmitted: (_) {
              final results = _results.value;
              if (results.length == 1) _select(results.single);
            },
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
      ],
    );

    final list = ValueListenableBuilder<List<Country>>(
      valueListenable: _results,
      builder: (context, countries, _) => ListView.separated(
        controller: widget.scrollController,
        // The sheet replaces MediaQuery.padding (for its drag handle), so read
        // the home indicator inset from viewPadding.
        padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: countries.length,
        separatorBuilder: (_, _) => style?.showDividers ?? true
            ? Padding(
                padding: EdgeInsetsDirectional.only(start: separatorIndent),
                child: SizedBox(height: 0.5, child: ColoredBox(color: separatorColor)),
              )
            : const SizedBox.shrink(),
        itemBuilder: (context, index) {
          final country = countries[index];
          final selected = isSameCountry(country, widget.selectedCountry);
          return CupertinoListTile(
            padding: style?.listTilePadding,
            leadingSize: flagWidth,
            leading: CountryFlag(country: country, width: flagWidth),
            title: Text(_filter.nameOf(country), style: style?.countryNameStyle),
            additionalInfo: Text('+${country.displayCC}', style: style?.countryCodeStyle),
            trailing: SizedBox(
              width: 20,
              child: selected
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: 20,
                      color: style?.checkmarkColor ?? CupertinoTheme.of(context).primaryColor,
                    )
                  : null,
            ),
            onTap: () => _select(country),
          );
        },
      ),
    );

    // The insets that change while the keyboard animates are read by the small
    // builders below, so each frame doesn't rebuild the search field or the
    // list rows.
    return ColoredBox(
      color: style?.backgroundColor ?? CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: <Widget>[
          Builder(
            builder: (context) => Padding(
              padding:
                  style?.searchFieldPadding ??
                  EdgeInsetsDirectional.fromSTEB(16, MediaQuery.paddingOf(context).top + 8, 4, 8),
              child: searchRow,
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final keyboard = MediaQuery.viewInsetsOf(context).bottom - MediaQuery.viewPaddingOf(context).bottom;
                return Padding(
                  padding: EdgeInsets.only(bottom: math.max(0, keyboard)),
                  child: list,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
