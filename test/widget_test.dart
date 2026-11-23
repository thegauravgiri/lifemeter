import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/main.dart';
import 'package:lifemeter/models/profile.dart';
import 'package:lifemeter/services/profile_store.dart';
import 'package:lifemeter/services/widget_sync.dart';
import 'package:lifemeter/state/life_controller.dart';
import 'package:lifemeter/theme/icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LifeController> _pumpApp(WidgetTester tester) async {
  // Phone width, extra tall so every home section is laid out regardless of
  // date-dependent content (e.g. the Monday "New week" line).
  tester.view.physicalSize = const Size(1170, 4200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = LifeController(ProfileStore(), WidgetSync());
  await tester.runAsync(controller.load);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: const LifeMeterApp(),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('first launch shows onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpApp(tester);
    expect(find.text('Count mine'), findsOneWidget);

    // Welcome → birthday → country → sex → reveal: four taps plus inputs.
    await tester.ensureVisible(find.text('Count mine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Count mine'));
    await tester.pumpAndSettle();
    expect(find.text('When did your day begin?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nep');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nepal'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('in your life'), findsOneWidget);
    expect(find.text('Make them count'), findsOneWidget);
    expect(find.text('Share my time'), findsOneWidget);
    expect(
      find.text('An estimate from population data, not a prediction.'),
      findsOneWidget,
    );

    // Habits come after the payoff, and can be skipped.
    await tester.ensureVisible(find.text('Make them count'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make them count'));
    await tester.pumpAndSettle();
    expect(find.text('Do you smoke?'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('one thing with the time ahead'),
      findsOneWidget,
    );
  });

  testWidgets('a saved profile opens the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await _pumpApp(tester);
    await tester.runAsync(
      () => controller.save(
        Profile(
          birthDate: DateTime(1990, 5, 1),
          countryCode: 'NP',
          intention: 'Learn piano',
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('in your life'), findsOneWidget);
    expect(find.text('Learn piano'), findsOneWidget);
    expect(find.text('Bucket list'), findsOneWidget);

    // The one-thing card has an explicit edit button that opens the editor.
    await tester.tap(find.byTooltip('Edit'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your one thing'), findsNWidgets(2)); // block + sheet
    expect(find.text('Save'), findsOneWidget);
    Navigator.of(tester.element(find.text('Save'))).pop();
    await tester.pump(const Duration(seconds: 1));

    // Ticking off the one thing turns the card into a "what's next" prompt.
    await tester.runAsync(() => controller.addBucketItem('Learn piano'));
    final pianoId = controller.bucket
        .firstWhere((i) => i.text == 'Learn piano')
        .id;
    await tester.runAsync(() => controller.toggleBucketItem(pianoId));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Pick the next one'), findsOneWidget);
    expect(find.textContaining('What’s the next one thing?'), findsOneWidget);
    await tester.runAsync(() => controller.toggleBucketItem(pianoId));
    await tester.pump(const Duration(seconds: 1));

    // Bucket items show on home and can be ticked off.
    await tester.runAsync(() => controller.addBucketItem('Plant a tree'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Plant a tree'), findsOneWidget);
    expect(
      find.text(
        '2 to go · about ${controller.estimate!.at(DateTime.now()).remainingSummers} summers',
      ),
      findsOneWidget,
    );

    // The hero rotates on its own: back on the clock, wait one interval.
    await tester.runAsync(() => controller.setUnit(HeroUnit.clock));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const LifeMeterApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('in your life'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('weeks left'), findsOneWidget);

    // With the slideshow off, taps cycle through every view:
    // clock → weeks → days → hours → seconds → summers → % lived.
    await tester.runAsync(() => controller.setSlideshow(false));
    await tester.runAsync(() => controller.setUnit(HeroUnit.clock));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const LifeMeterApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    for (final label in [
      'weeks left',
      'days left',
      'hours left',
      'seconds left',
      'summers left',
      'of the day behind you',
      'in your life',
    ]) {
      await tester.tap(find.byIcon(LMIcons.caretUpDown));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(label), findsOneWidget);
    }
  });

  test('migrates v1 preferences', () async {
    SharedPreferences.setMockInitialValues({
      'country': 'Japan',
      'dob': '1994-02-03',
    });
    final profile = await ProfileStore().load();
    expect(profile, isNotNull);
    expect(profile!.countryCode, 'JP');
    expect(profile.birthDate, DateTime(1994, 2, 3));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('dob'), isFalse);
  });
}
