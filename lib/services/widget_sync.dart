import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/life_estimate.dart';

/// The home-screen widgets LifeMeter offers.
enum HomeWidgetKind { clock, countdown, weeks }

/// Pushes the estimate to the Android home-screen widget.
///
/// The widget computes "days left" natively from these timestamps, so it
/// stays current without the app being opened.
class WidgetSync {
  static const _provider = 'np.com.gauravgiri.lifemeter.LifeWidgetProvider';
  static const _weeksProvider =
      'np.com.gauravgiri.lifemeter.LifeWeeksWidgetProvider';
  static const _clockProvider =
      'np.com.gauravgiri.lifemeter.LifeClockWidgetProvider';

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> push(
    LifeEstimate? estimate, {
    String intention = '',
    String unit = 'weeks',
    Iterable<int> marked = const [],
  }) async {
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        'lm_birth_ms',
        estimate?.birth.millisecondsSinceEpoch.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'lm_end_ms',
        estimate?.end.millisecondsSinceEpoch.toString(),
      );
      await HomeWidget.saveWidgetData<String>('lm_intention', intention);
      await HomeWidget.saveWidgetData<String>('lm_unit', unit);
      // Weeks with a memory, drawn pink on the weeks widget.
      await HomeWidget.saveWidgetData<String>('lm_marked', marked.join(','));
      for (final p in [_provider, _weeksProvider, _clockProvider]) {
        await HomeWidget.updateWidget(qualifiedAndroidName: p);
      }
    } catch (e) {
      debugPrint('Widget sync skipped: $e');
    }
  }

  Future<bool> canPin() async {
    if (!_supported) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// True when pinning is possible and no LifeMeter widget is placed yet.
  Future<bool> shouldPromote() async {
    if (!await canPin()) return false;
    try {
      return (await HomeWidget.getInstalledWidgets()).isEmpty;
    } catch (_) {
      return true;
    }
  }

  /// Asks the launcher to place a widget.
  Future<void> requestPin([HomeWidgetKind kind = HomeWidgetKind.clock]) async {
    if (!_supported) return;
    try {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: switch (kind) {
          HomeWidgetKind.clock => _clockProvider,
          HomeWidgetKind.countdown => _provider,
          HomeWidgetKind.weeks => _weeksProvider,
        },
      );
    } catch (e) {
      debugPrint('Pin widget failed: $e');
    }
  }
}
