import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/site.dart';

/// Sharing, saving and wallpaper: things done with a rendered PNG. Nothing
/// is uploaded; the system share sheet decides where an image goes.
class DeviceActions {
  const DeviceActions();

  static const _channel = MethodChannel('lifemeter/device');

  static const shareText = 'What time is it in your life? ${Site.host}';

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> sharePng(Uint8List png, {String name = 'lifemeter.png'}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
        text: shareText,
      ),
    );
  }

  /// Saves to Pictures/LifeMeter. Returns false where unsupported.
  Future<bool> savePng(Uint8List png, {String name = 'lifemeter'}) async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('saveImage', {
            'bytes': png,
            'name': name,
          }) ??
          false;
    } on PlatformException catch (e) {
      debugPrint('Save failed: $e');
      return false;
    }
  }

  /// Sets [png] as the lock-screen wallpaper. Returns false on failure.
  Future<bool> setLockScreen(Uint8List png) async {
    if (!_android) return false;
    try {
      return await _channel.invokeMethod<bool>('setLockScreen', {
            'bytes': png,
          }) ??
          false;
    } on PlatformException catch (e) {
      debugPrint('Wallpaper failed: $e');
      return false;
    }
  }
}
