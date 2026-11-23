// Renders LifeMeter's key screens to PNG (light + dark) for design review.
//
// Opt-in, so the normal `flutter test` run skips it:
//   flutter test test/screenshots/render_screens_test.dart --dart-define=RENDER=true
//
// Output: build/screens/<screen>-<light|dark>.png (2x pixel ratio, real
// fonts). Share cards are written once, at their real 1080×1920 size.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/models/milestones.dart';
import 'package:lifemeter/models/person.dart';
import 'package:lifemeter/models/profile.dart';
import 'package:lifemeter/models/week_memory.dart';
import 'package:lifemeter/screens/bucket/bucket_list_screen.dart';
import 'package:lifemeter/screens/home/home_screen.dart';
import 'package:lifemeter/screens/onboarding/onboarding_flow.dart';
import 'package:lifemeter/screens/people/people_sheets.dart';
import 'package:lifemeter/screens/settings/settings_screen.dart';
import 'package:lifemeter/screens/share/share_sheet.dart';
import 'package:lifemeter/services/profile_store.dart';
import 'package:lifemeter/services/widget_sync.dart';
import 'package:lifemeter/state/life_controller.dart';
import 'package:lifemeter/theme/theme.dart';
import 'package:lifemeter/widgets/share_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _render = bool.fromEnvironment('RENDER');
const _phone = Size(390, 844);
final _outDir = Directory('build/screens');

final _profile = Profile(
  name: 'Gaurav',
  birthDate: DateTime(1995, 8, 15),
  countryCode: 'NP',
  sex: Sex.male,
  lifestyle: const {'smoking': 'never', 'activity': 'some'},
  intention: 'See the northern lights',
);

Future<void> _loadFonts() async {
  Future<void> load(String family, List<Future<ByteData>> fonts) async {
    final loader = FontLoader(family);
    fonts.forEach(loader.addFont);
    await loader.load();
  }

  await load('BigShoulders', [
    for (final w in [800, 900])
      rootBundle.load('assets/fonts/BigShouldersDisplay-$w.ttf'),
  ]);
  await load('Schibsted', [
    for (final w in [400, 500, 700])
      rootBundle.load('assets/fonts/SchibstedGrotesk-$w.ttf'),
  ]);
  for (final style in ['Bold', 'Fill']) {
    await load('Phosphor$style', [
      rootBundle.load('assets/fonts/Phosphor-$style.ttf'),
    ]);
  }
  // Roboto is the platform fallback; Material icons come from the SDK.
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final fonts = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> file(String name) async =>
      ByteData.sublistView(await File('$fonts/$name').readAsBytes());
  await load('MaterialIcons', [file('MaterialIcons-Regular.otf')]);
  await load('Roboto', [file('Roboto-Regular.ttf'), file('Roboto-Medium.ttf')]);
}

final _boundary = GlobalKey();

Widget _app(LifeController c, Widget home, Brightness b) => RepaintBoundary(
  key: _boundary,
  child: ChangeNotifierProvider.value(
    value: c,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(LMPalette.light),
      darkTheme: buildTheme(LMPalette.dark),
      themeMode: b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  ),
);

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Brightness? b, {
  double ratio = 2,
  GlobalKey? key,
}) async {
  await tester.runAsync(() async {
    final boundary =
        (key ?? _boundary).currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final suffix = b == null ? '' : '-${b.name}';
    final file = File('${_outDir.path}/$name$suffix.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<LifeController> _controller(
  WidgetTester tester, {
  bool withProfile = true,
  Profile? profile,
}) async {
  SharedPreferences.setMockInitialValues({});
  final c = LifeController(ProfileStore(), WidgetSync());
  await tester.runAsync(() async {
    await c.load();
    if (!withProfile) return;
    await c.save(profile ?? _profile);
    for (final item in [
      'See the northern lights',
      'Learn to surf',
      'Visit Japan',
      'Write letters to people I love',
      'Plant a tree',
    ]) {
      await c.addBucketItem(item);
    }
    await c.toggleBucketItem(
      c.bucket.firstWhere((i) => i.text == 'Plant a tree').id,
    );
    final e = c.estimate!;
    for (final (date, text, stamp) in [
      (DateTime(2013, 4, 2), 'Finished school', 'party'),
      (DateTime(2019, 6, 20), 'First job', 'peak'),
      (DateTime(2022, 10, 5), 'Trek to Mardi', 'trip'),
      (DateTime(2025, 2, 14), 'Met Asha', 'heart'),
    ]) {
      await c.saveMemory(
        WeekMemory(week: e.weekIndexOf(date), text: text, stamp: stamp),
      );
    }
    await c.addPerson(
      Person.create(label: 'Mum', birthYear: 1968, visitsPerYear: 4),
    );
    await c.addPerson(
      Person.create(label: 'Grandpa', birthYear: 1944, visitsPerYear: 2),
    );
  });
  return c;
}

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(HomeScreen));

void main() {
  setUpAll(() async {
    if (!_render) return;
    _outDir.createSync(recursive: true);
    await _loadFonts();
  });

  for (final b in Brightness.values) {
    testWidgets('onboarding ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      final c = await _controller(tester, withProfile: false);
      await tester.pumpWidget(_app(c, const OnboardingFlow(), b));
      await _settle(tester, 2000);
      await _shoot(tester, '01-welcome', b);

      await tester.tap(find.text('Count mine'));
      await _settle(tester);
      await _shoot(tester, '02-question-birth', b);

      await tester.tap(find.text('Continue'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'nep');
      await _settle(tester, 500);
      await tester.tap(find.text('Nepal'));
      await _settle(tester, 500);
      await _shoot(tester, '03-question-country', b);

      await tester.tap(find.text('Continue'));
      await _settle(tester);
      await _shoot(tester, '04-question-sex', b);

      await tester.tap(find.text('Male'));
      await _settle(tester, 5500);
      await _shoot(tester, '05-reveal', b);

      await tester.enterText(find.byType(TextField), 'Gaurav');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester, 500);
      await tester.tap(find.text('Make them count'));
      await _settle(tester);
      await tester.tap(find.text('Never'));
      await _settle(tester);
      await tester.tap(find.text('Active'));
      await _settle(tester);
      await _shoot(tester, '06-sharpen-estimate', b);

      await tester.tap(find.text('Skip'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Visit Japan');
      await _settle(tester, 500);
      await _shoot(tester, '07-one-thing', b);
    });

    testWidgets('home ($b)', skip: !_render, (tester) async {
      // Tall surface so the whole scrolling page is in one image.
      _size(tester, const Size(390, 3000));
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const HomeScreen(), b));
      await _settle(tester);
      await _shoot(tester, '08-home-full', b);
    });

    testWidgets('tail end, all cards ($b)', skip: !_render, (tester) async {
      // Wide enough that every tail-end card is on screen at once.
      _size(tester, const Size(1120, 3600));
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const HomeScreen(), b));
      await _settle(tester);
      await _shoot(tester, '08c-home-wide', b);
    });

    testWidgets('home first screen ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const HomeScreen(), b));
      await _settle(tester);
      await _shoot(tester, '09-home-above-fold', b);

      await tester.tap(find.text('What will make it count?'));
      await _settle(tester, 800);
      await tester.enterText(
        find.byType(TextField).last,
        'Sunrise at Nagarkot',
      );
      await tester.tap(find.bySemanticsLabel('Good day'));
      await _settle(tester, 800);
      await _shoot(tester, '10-week-memory', b);
    });

    testWidgets('people ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const HomeScreen(), b));
      await _settle(tester, 500);
      showPersonSheet(_ctx(tester), c.people.first);
      await _settle(tester, 1000);
      await _shoot(tester, '11-people', b);
    });

    testWidgets('share sheet ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const HomeScreen(), b));
      await _settle(tester, 500);
      showShareSheet(_ctx(tester), shareDataFor(c, DateTime.now()));
      await _settle(tester, 1000);
      await _shoot(tester, '12-share-sheet', b);
    });

    testWidgets('bucket list ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const BucketListScreen(), b));
      await _settle(tester);
      await _shoot(tester, '13-bucket-list', b);
    });

    testWidgets('settings ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const SettingsScreen(), b));
      await _settle(tester);
      await _shoot(tester, '14-settings', b);
    });

    testWidgets('settings full ($b)', skip: !_render, (tester) async {
      _size(tester, const Size(390, 2300));
      final c = await _controller(tester);
      await tester.pumpWidget(_app(c, const SettingsScreen(), b));
      await _settle(tester);
      await _shoot(tester, '14-settings-full', b);
    });

    testWidgets('home with milestone ($b)', skip: !_render, (tester) async {
      _size(tester, _phone);
      // Born 12,459 days ago: 12,500 days old in 41 days.
      final now = DateTime.now();
      final birth = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 12459));
      final c = await _controller(
        tester,
        profile: _profile.copyWith(birthDate: birth),
      );
      await tester.pumpWidget(_app(c, const HomeScreen(), b));
      await _settle(tester);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
      await _settle(tester, 600);
      await _shoot(tester, '09b-home-milestone', b);
    });
  }

  testWidgets('share cards', skip: !_render, (tester) async {
    final c = await _controller(tester);
    final now = DateTime.now();
    final s = c.estimate!.at(now);
    // A realistic upcoming state: 12,500 days old in 41 days.
    final m = milestonesFor(
      c.estimate!,
    ).firstWhere((m) => m.kind == MilestoneKind.days && m.value == 12500);
    final milestone = Milestone(
      kind: m.kind,
      value: m.value,
      date: DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 41)),
      title: m.title,
      unit: m.unit,
      note: m.note,
    );
    final data = ShareData(
      snapshot: s,
      name: 'Gaurav',
      marked: c.memories.keys.toSet(),
      milestone: milestone,
      personLabel: 'Mum',
      personVisits: visitsWith(c, c.people.first, now),
    );
    for (final (i, template) in ShareTemplate.values.indexed) {
      for (final cobalt in [true, false]) {
        if (!cobalt && template != ShareTemplate.clock) continue;
        _size(tester, template.size);
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Center(
              child: RepaintBoundary(
                key: key,
                child: ShareCard(
                  template: template,
                  data: data,
                  cobalt: cobalt,
                  showName: template == ShareTemplate.weeks,
                ),
              ),
            ),
          ),
        );
        await _settle(tester, 300);
        await _shoot(
          tester,
          '${15 + i}-share-${template.name}${cobalt ? '' : '-light'}',
          null,
          ratio: 3,
          key: key,
        );
      }
    }
  });
}
