import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppMode {
  static const _channel = MethodChannel('com.technews/device');

  static bool isWearable = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      isWearable = await _channel.invokeMethod<bool>('isWearable') ?? false;
    } on MissingPluginException {
      // Non-Android Flutter targets use the responsive layout instead.
    }
  }
}
