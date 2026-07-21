import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinVerificationResult {
  final bool isValid;
  final DateTime? lockedUntil;
  final int remainingAttempts;

  const PinVerificationResult({
    required this.isValid,
    required this.remainingAttempts,
    this.lockedUntil,
  });

  bool get isLocked => lockedUntil != null;
}

/// Stores only a salted PIN verifier. The original PIN is never persisted.
class PinSecurityService {
  static const _saltKey = 'wear_pin_salt';
  static const _verifierKey = 'wear_pin_verifier';
  static const _failedAttemptsKey = 'wear_pin_failed_attempts';
  static const _lockedUntilKey = 'wear_pin_locked_until';
  static const _pinLength = 6;
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  Future<bool> hasPin() async =>
      await _storage.read(key: _verifierKey) != null &&
      await _storage.read(key: _saltKey) != null;

  Future<void> createPin(String pin) async {
    _validatePin(pin);
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final verifier = await _deriveVerifier(pin, salt);
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _verifierKey, value: base64Encode(verifier));
    await _clearFailures();
  }

  Future<PinVerificationResult> verifyPin(String pin) async {
    _validatePin(pin);
    final lockedUntil = await _getLockedUntil();
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      return PinVerificationResult(
        isValid: false,
        lockedUntil: lockedUntil,
        remainingAttempts: 0,
      );
    }

    final saltValue = await _storage.read(key: _saltKey);
    final verifierValue = await _storage.read(key: _verifierKey);
    if (saltValue == null || verifierValue == null) {
      throw StateError('No hay un PIN configurado.');
    }

    final actual = await _deriveVerifier(pin, base64Decode(saltValue));
    final expected = base64Decode(verifierValue);
    if (_constantTimeEquals(actual, expected)) {
      await _clearFailures();
      return const PinVerificationResult(isValid: true, remainingAttempts: _maxAttempts);
    }

    final failures = (int.tryParse(
              await _storage.read(key: _failedAttemptsKey) ?? '0',
            ) ??
            0) +
        1;
    if (failures >= _maxAttempts) {
      final until = DateTime.now().add(_lockDuration);
      await _storage.write(
        key: _lockedUntilKey,
        value: until.millisecondsSinceEpoch.toString(),
      );
      await _storage.write(key: _failedAttemptsKey, value: '0');
      return PinVerificationResult(
        isValid: false,
        lockedUntil: until,
        remainingAttempts: 0,
      );
    }

    await _storage.write(key: _failedAttemptsKey, value: failures.toString());
    return PinVerificationResult(
      isValid: false,
      remainingAttempts: _maxAttempts - failures,
    );
  }

  Future<List<int>> _deriveVerifier(String pin, List<int> salt) async {
    final secretKey = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  Future<DateTime?> _getLockedUntil() async {
    final value = await _storage.read(key: _lockedUntilKey);
    final milliseconds = value == null ? null : int.tryParse(value);
    if (milliseconds == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    if (DateTime.now().isBefore(until)) return until;
    await _storage.delete(key: _lockedUntilKey);
    return null;
  }

  Future<void> _clearFailures() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockedUntilKey);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('El PIN debe tener seis dígitos.');
    }
  }
}
