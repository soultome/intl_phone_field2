import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../countries.dart';

/// Emoji flags are not rendered by the default fonts on the web and Windows,
/// so the bundled PNG flags are used there instead.
bool get useImageFlags => kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

/// Displays a country's flag as an emoji, or as an image where emoji flags are
/// not supported.
///
/// The flag always occupies a fixed `width × width * 0.75` box so rows don't
/// shift while images load or when the selected country changes.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.country, this.width = 32, this.gaplessPlayback = false});

  final Country country;

  /// Width of the flag image. Emoji flags are scaled proportionally (a width
  /// of 32 renders an 18pt emoji).
  final double width;

  /// Keep showing the previous flag image until the new one has loaded. Use it
  /// where the country changes in place (the field's button), but not in
  /// lists, where a recycled row would briefly show another country's flag.
  final bool gaplessPlayback;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.75;
    if (useImageFlags) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          'assets/flags/${country.code.toLowerCase()}.png',
          package: 'intl_phone_field2',
          fit: BoxFit.contain,
          gaplessPlayback: gaplessPlayback,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return ExcludeSemantics(
      child: Text(country.flag, style: TextStyle(fontSize: width * 0.5625)),
    );
  }
}
