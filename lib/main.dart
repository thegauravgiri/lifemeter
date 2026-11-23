import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/profile_store.dart';
import 'services/widget_sync.dart';
import 'state/life_controller.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _registerFontLicenses();

  final controller = LifeController(ProfileStore(), WidgetSync());
  await controller.load();

  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const LifeMeterApp(),
    ),
  );
}

class LifeMeterApp extends StatelessWidget {
  const LifeMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isSetUp = context.select<LifeController, bool>((c) => c.isSetUp);
    final theme = context.select<LifeController, AppTheme>((c) => c.theme);
    return MaterialApp(
      title: 'LifeMeter',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(LMPalette.light),
      darkTheme: buildTheme(LMPalette.dark),
      themeMode: switch (theme) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
      },
      // Status/navigation bar icons follow the active palette.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle(context.lm),
        child: child!,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: isSetUp
            ? const HomeScreen(key: ValueKey('home'))
            : const OnboardingFlow(key: ValueKey('onboarding')),
      ),
    );
  }
}

/// Bundled font licences (SIL OFL for the text faces, MIT for Phosphor),
/// shown on the system licence page.
void _registerFontLicenses() {
  const fonts = {
    'Big Shoulders Display': 'assets/fonts/BigShouldersDisplay-OFL.txt',
    'Schibsted Grotesk': 'assets/fonts/SchibstedGrotesk-OFL.txt',
    'Phosphor Icons': 'assets/fonts/Phosphor-LICENSE.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path) in fonts.entries) {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString(path));
    }
  });
}
