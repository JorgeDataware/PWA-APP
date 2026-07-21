import 'package:flutter/foundation.dart';

import '../core/app_mode.dart';
import '../services/pin_security_service.dart';

class WearPinProvider extends ChangeNotifier {
  final PinSecurityService _service;

  WearPinProvider({PinSecurityService? service})
      : _service = service ?? PinSecurityService();

  bool _ready = false;
  bool _hasPin = false;
  bool _isUnlocked = false;

  bool get ready => _ready;
  bool get needsSetup => !_hasPin;
  bool get isUnlocked => _isUnlocked;

  Future<void> initialize() async {
    if (AppMode.isWearable) _hasPin = await _service.hasPin();
    _ready = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _service.createPin(pin);
    _hasPin = true;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<PinVerificationResult> unlock(String pin) async {
    final result = await _service.verifyPin(pin);
    if (result.isValid) {
      _isUnlocked = true;
      notifyListeners();
    }
    return result;
  }

  void lock() {
    if (!_isUnlocked) return;
    _isUnlocked = false;
    notifyListeners();
  }
}
