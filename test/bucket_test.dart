import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/models/bucket_item.dart';
import 'package:lifemeter/models/profile.dart';
import 'package:lifemeter/services/profile_store.dart';
import 'package:lifemeter/services/widget_sync.dart';
import 'package:lifemeter/state/life_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LifeController> _controller() async {
  final c = LifeController(ProfileStore(), WidgetSync());
  await c.load();
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('adds items, ignoring blanks and duplicates', () async {
    final c = await _controller();
    await c.addBucketItem('Visit Japan');
    await c.addBucketItem('  visit japan ');
    await c.addBucketItem('   ');
    expect(c.bucket.map((i) => i.text), ['Visit Japan']);
  });

  test('done items sort after open ones and can be undone', () async {
    final c = await _controller();
    await c.addBucketItem('A');
    await c.addBucketItem('B');
    final a = c.bucket.first;
    await c.toggleBucketItem(a.id);
    expect(c.bucket.map((i) => i.text), ['B', 'A']);
    expect(c.bucket.last.isDone, isTrue);
    await c.toggleBucketItem(a.id);
    expect(c.bucket.every((i) => !i.isDone), isTrue);
  });

  test('edit, remove and restore', () async {
    final c = await _controller();
    await c.addBucketItem('Run');
    final item = c.bucket.single;
    await c.editBucketItem(item.id, 'Run a marathon');
    expect(c.bucket.single.text, 'Run a marathon');
    final edited = c.bucket.single;
    await c.removeBucketItem(edited.id);
    expect(c.bucket, isEmpty);
    await c.restoreBucketItem(edited);
    expect(c.bucket.single.text, 'Run a marathon');
  });

  test('pinning sets the one thing', () async {
    final c = await _controller();
    await c.save(Profile(birthDate: DateTime(1990), countryCode: 'NP'));
    await c.addBucketItem('Learn piano');
    await c.pinBucketItem(c.bucket.single.id);
    expect(c.profile!.intention, 'Learn piano');
  });

  test('persists across launches and clears on reset', () async {
    final c = await _controller();
    await c.save(Profile(birthDate: DateTime(1990), countryCode: 'NP'));
    await c.addBucketItem('Plant a tree');
    await c.toggleBucketItem(c.bucket.single.id);

    final reloaded = await _controller();
    expect(reloaded.bucket.single.text, 'Plant a tree');
    expect(reloaded.bucket.single.isDone, isTrue);

    await reloaded.reset();
    expect((await _controller()).bucket, isEmpty);
  });

  test('existing one thing seeds a new bucket list once', () async {
    SharedPreferences.setMockInitialValues({});
    await ProfileStore().save(
      Profile(
        birthDate: DateTime(1990),
        countryCode: 'NP',
        intention: 'See the northern lights',
      ),
    );
    final c = await _controller();
    expect(c.bucket.single.text, 'See the northern lights');

    await c.removeBucketItem(c.bucket.single.id);
    expect((await _controller()).bucket, isEmpty); // not re-seeded
  });

  test('widget unit persists and resets', () async {
    final c = await _controller();
    expect(c.widgetUnit, WidgetUnit.slideshow);
    await c.setWidgetUnit(WidgetUnit.seconds);
    expect((await _controller()).widgetUnit, WidgetUnit.seconds);
    await c.reset();
    expect((await _controller()).widgetUnit, WidgetUnit.slideshow);
  });

  test('BucketItem JSON round trip and bad input', () {
    final item = BucketItem.create(
      'See an eclipse',
    ).copyWith(doneAt: DateTime(2030, 4, 8));
    final back = BucketItem.fromJson(item.toJson())!;
    expect(back.id, item.id);
    expect(back.text, item.text);
    expect(back.doneAt, DateTime(2030, 4, 8));
    expect(BucketItem.fromJson({'text': 'no id'}), isNull);
    expect(BucketItem.fromJson('nope'), isNull);
  });
}
