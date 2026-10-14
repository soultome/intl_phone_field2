import 'dart:math' as math;

import 'package:intl_phone_field2/countries.dart';
import 'package:intl_phone_field2/src/country_flag.dart';
import 'package:intl_phone_field2/src/country_utils.dart';
import 'package:material_ui/material_ui.dart';

class PickerDialogStyle {
  final Color? backgroundColor;

  final TextStyle? countryCodeStyle;

  final TextStyle? countryNameStyle;

  final Widget? listTileDivider;

  final EdgeInsets? listTilePadding;

  final EdgeInsets? padding;

  final Color? searchFieldCursorColor;

  final InputDecoration? searchFieldInputDecoration;

  final EdgeInsets? searchFieldPadding;

  final double? width;

  const PickerDialogStyle({
    this.backgroundColor,
    this.countryCodeStyle,
    this.countryNameStyle,
    this.listTileDivider,
    this.listTilePadding,
    this.padding,
    this.searchFieldCursorColor,
    this.searchFieldInputDecoration,
    this.searchFieldPadding,
    this.width,
  });
}

/// A Material dialog to search for and pick a country.
///
/// By default the dialog is centered on screen. When [anchorRect] is set it is
/// shown as a dropdown attached to that rectangle instead: below it, or above
/// it when there is more room there, and always kept on screen.
class CountryPickerDialog extends StatefulWidget {
  final List<Country> countryList;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final String searchText;
  final PickerDialogStyle? style;
  final String languageCode;

  /// Width of the dialog. Overrides [PickerDialogStyle.width].
  final double? popupWidth;

  /// The rectangle, in the coordinate space of the dialog's [Overlay], to
  /// attach the dialog to.
  final Rect? anchorRect;

  const CountryPickerDialog({
    super.key,
    required this.countryList,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.searchText = 'Search country',
    this.languageCode = 'en',
    this.style,
    this.popupWidth,
    this.anchorRect,
  });

  @override
  CountryPickerDialogState createState() => CountryPickerDialogState();
}

class CountryPickerDialogState extends State<CountryPickerDialog> {
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
  void didUpdateWidget(CountryPickerDialog oldWidget) {
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
    final width = widget.popupWidth ?? style?.width;
    final content = Padding(
      padding: style?.padding ?? const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Padding(
            padding: style?.searchFieldPadding ?? EdgeInsets.zero,
            child: TextField(
              cursorColor: style?.searchFieldCursorColor,
              decoration:
                  style?.searchFieldInputDecoration ??
                  InputDecoration(suffixIcon: const Icon(Icons.search), labelText: widget.searchText),
              textInputAction: TextInputAction.search,
              onChanged: _search,
              onSubmitted: (_) {
                final results = _results.value;
                if (results.length == 1) _select(results.single);
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ValueListenableBuilder<List<Country>>(
              valueListenable: _results,
              builder: (context, countries, _) => ListView.separated(
                padding: EdgeInsets.zero,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: countries.length,
                separatorBuilder: (_, _) => style?.listTileDivider ?? const Divider(thickness: 1),
                itemBuilder: (context, index) {
                  final country = countries[index];
                  return ListTile(
                    leading: CountryFlag(country: country),
                    contentPadding: style?.listTilePadding,
                    selected: isSameCountry(country, widget.selectedCountry),
                    title: Text(
                      _filter.nameOf(country),
                      style: style?.countryNameStyle ?? const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: Text(
                      '+${country.displayCC}',
                      style: style?.countryCodeStyle ?? const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => _select(country),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    final anchorRect = widget.anchorRect;
    if (anchorRect == null) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        backgroundColor: style?.backgroundColor,
        child: SizedBox(width: width ?? double.maxFinite, child: content),
      );
    }

    return _AnchoredPopup(
      anchor: anchorRect,
      width: width,
      child: Material(
        color: style?.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

/// Positions [child] next to [anchor], within the safe area and above the
/// keyboard.
///
/// It reads the insets itself so that, while the keyboard animates, only the
/// layout updates and the picker's content isn't rebuilt every frame.
class _AnchoredPopup extends StatelessWidget {
  const _AnchoredPopup({required this.anchor, required this.width, required this.child});

  final Rect anchor;
  final double? width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);
    return CustomSingleChildLayout(
      delegate: _AnchoredPopupLayout(
        anchor: anchor,
        width: width,
        padding:
            EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, math.max(padding.bottom, viewInsets.bottom)) +
            const EdgeInsets.all(8),
        textDirection: Directionality.of(context),
      ),
      child: child,
    );
  }
}

/// Places the picker next to its anchor: below it when there is enough room
/// (or more room than above), otherwise above it.
class _AnchoredPopupLayout extends SingleChildLayoutDelegate {
  const _AnchoredPopupLayout({
    required this.anchor,
    required this.width,
    required this.padding,
    required this.textDirection,
  });

  static const double _maxHeight = 400;
  static const double _minHeight = 200;
  static const double _minWidth = 280;

  final Rect anchor;
  final double? width;
  final EdgeInsets padding;
  final TextDirection textDirection;

  ({bool below, double height}) _placement(Rect bounds) {
    final spaceBelow = bounds.bottom - anchor.bottom;
    final spaceAbove = anchor.top - bounds.top;
    final below = spaceBelow >= _minHeight || spaceBelow >= spaceAbove;
    final space = below ? spaceBelow : spaceAbove;
    return (below: below, height: space.clamp(math.min(_minHeight, bounds.height), _maxHeight));
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final bounds = padding.deflateRect(Offset.zero & constraints.biggest);
    final preferredWidth = width ?? math.max(anchor.width, _minWidth);
    return BoxConstraints.tight(
      Size(math.max(0, math.min(preferredWidth, bounds.width)), math.max(0, _placement(bounds).height)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bounds = padding.deflateRect(Offset.zero & size);
    final x = textDirection == TextDirection.ltr ? anchor.left : anchor.right - childSize.width;
    final y = _placement(bounds).below ? anchor.bottom : anchor.top - childSize.height;
    return Offset(
      x.clamp(bounds.left, math.max(bounds.left, bounds.right - childSize.width)),
      y.clamp(bounds.top, math.max(bounds.top, bounds.bottom - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_AnchoredPopupLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      width != oldDelegate.width ||
      padding != oldDelegate.padding ||
      textDirection != oldDelegate.textDirection;
}
