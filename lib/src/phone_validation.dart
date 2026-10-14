import 'dart:async';

import '../countries.dart';
import '../phone_number.dart';

final RegExp _digits = RegExp(r'^\d+$');

typedef PhoneValidator = FutureOr<String?> Function(PhoneNumber?);

PhoneNumber phoneNumberFor(Country country, String number) =>
    PhoneNumber(countryISOCode: country.code, countryCode: '+${country.fullCountryCode}', number: number);

/// Validation shared by the Material and Cupertino phone fields.
///
/// Runs the built-in length check, then the user's validator. Synchronous
/// validators run on every validation. An asynchronous validator runs once per
/// distinct number; until it completes the previous message is kept, and
/// [onAsyncResult] is called so the field can validate again and show the new
/// message.
class PhoneFieldValidation {
  PhoneFieldValidation({required this.onAsyncResult});

  final void Function() onAsyncResult;

  String? _message;
  String? _asyncKey;
  bool _disposed = false;

  String? validate({
    required String? value,
    required Country country,
    required bool disableLengthCheck,
    required String? invalidNumberMessage,
    required PhoneValidator? validator,
  }) {
    final text = value ?? '';
    if (!disableLengthCheck && text.isNotEmpty) {
      final validLength = text.length >= country.minLength && text.length <= country.maxLength;
      if (!validLength || !_digits.hasMatch(text)) return invalidNumberMessage;
    }
    if (validator == null) return null;

    final phoneNumber = phoneNumberFor(country, text);
    final key = '${country.code}|${phoneNumber.completeNumber}';
    if (key == _asyncKey) return _message;

    final result = validator(phoneNumber);
    if (result is Future<String?>) {
      _asyncKey = key;
      unawaited(
        result.then((message) {
          if (_disposed || key != _asyncKey) return;
          _message = message;
          onAsyncResult();
        }),
      );
      return _message;
    }
    _asyncKey = null;
    return _message = result;
  }

  void dispose() => _disposed = true;
}
