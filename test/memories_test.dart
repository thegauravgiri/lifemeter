import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/models/profile.dart';
import 'package:lifemeter/models/week_memory.dart';
import 'package:lifemeter/services/profile_store.dart';
import 'package:lifemeter/services/widget_sync.dart';
import 'package:lifemeter/state/life_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('memories persist across restarts and stay short', () async {
    final c = LifeController(ProfileStore(), WidgetSync());
    await c.load();
    await c.save(Profile(birthDate: DateTime(1995, 8, 15), countryCode: 'NP'));
    final week = c.estimate!.weekIndexOf(DateTime(2022, 10, 5));
    await c.saveMemory(
      WeekMemory(week: week, text: 'Trek to Mardi', stamp: 'trip'),
    );
    await c.saveMemory(
      const WeekMemory(week: 10, text: 'This is far longer than twenty-four'),
    );

    final again = LifeController(ProfileStore(), WidgetSync());
    await again.load();
    expect(again.memories[week]!.text, 'Trek to Mardi');
    expect(again.memories[week]!.stamp, 'trip');
    expect(again.memories[10]!.text.length, WeekMemory.maxLength);

    // Blank text removes; reset clears.
    await again.saveMemory(const WeekMemory(week: 10, text: '  '));
    expect(again.memories.containsKey(10), isFalse);
    await again.reset();
    expect(again.memories, isEmpty);
  });

  test('ProfileStore round-trips memories', () async {
    final store = ProfileStore();
    await store.saveMemories([const WeekMemory(week: 3, text: 'Born-ish')]);
    final list = await store.loadMemories();
    expect(list.single.week, 3);
  });
}
