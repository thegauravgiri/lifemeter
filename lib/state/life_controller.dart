import 'package:flutter/foundation.dart';

import '../models/bucket_item.dart';
import '../models/life_estimate.dart';
import '../models/person.dart';
import '../models/profile.dart';
import '../models/week_memory.dart';
import '../services/profile_store.dart';
import '../services/widget_sync.dart';

/// What the home hero shows. Tap cycles through them.
enum HeroUnit {
  clock('Life clock'),
  weeks('Weeks left'),
  days('Days left'),
  hours('Hours left'),
  seconds('Seconds left'),
  summers('Summers left'),
  percent('Percent lived');

  const HeroUnit(this.label);
  final String label;

  HeroUnit get next => HeroUnit.values[(index + 1) % HeroUnit.values.length];

  static HeroUnit fromName(String? name) => HeroUnit.values.firstWhere(
    (u) => u.name == name,
    orElse: () => HeroUnit.clock,
  );
}

/// What the home-screen widget counts in.
enum WidgetUnit {
  slideshow(
    'Slideshow',
    'Rotates: life clock, years, weeks, days, hours, seconds',
  ),
  clock('Life clock', 'e.g. 10:48 AM in your life'),
  years('Years', 'e.g. 37.5 years left'),
  weeks('Weeks', 'e.g. 1,957 weeks left'),
  days('Days', 'e.g. 13,705 days left'),
  hours('Hours', 'e.g. 328,940 hours left'),
  seconds('Seconds', 'A live countdown that ticks every second');

  const WidgetUnit(this.label, this.detail);
  final String label;
  final String detail;

  static WidgetUnit fromName(String? name) => WidgetUnit.values.firstWhere(
    (u) => u.name == name,
    orElse: () => WidgetUnit.slideshow,
  );
}

/// Light, dark or follow the system.
enum AppTheme {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppTheme(this.label);
  final String label;

  static AppTheme fromName(String? name) => AppTheme.values.firstWhere(
    (t) => t.name == name,
    orElse: () => AppTheme.system,
  );
}

class LifeController extends ChangeNotifier {
  LifeController(this._store, this.widgets);

  final ProfileStore _store;
  final WidgetSync widgets;

  Profile? _profile;
  LifeEstimate? _estimate;
  HeroUnit _unit = HeroUnit.clock;
  Map<int, WeekMemory> _memories = {};
  List<Person> _people = [];
  bool _showPeople = true;
  List<BucketItem> _bucket = [];
  AppTheme _theme = AppTheme.system;
  bool _showSeconds = false;
  bool _slideshow = true;
  WidgetUnit _widgetUnit = WidgetUnit.slideshow;

  Profile? get profile => _profile;

  /// Bucket list: open items first (oldest first), then done (latest first).
  List<BucketItem> get bucket {
    final open = _bucket.where((i) => !i.isDone).toList();
    final done = _bucket.where((i) => i.isDone).toList()
      ..sort((a, b) => b.doneAt!.compareTo(a.doneAt!));
    return [...open, ...done];
  }

  LifeEstimate? get estimate => _estimate;
  HeroUnit get unit => _unit;

  /// Week memories by 0-based week index.
  Map<int, WeekMemory> get memories => Map.unmodifiable(_memories);

  List<Person> get people => List.unmodifiable(_people);

  /// The People section on home can be hidden in Settings.
  bool get showPeople => _showPeople;
  bool get isSetUp => _profile != null;
  AppTheme get theme => _theme;

  /// The live seconds ticker is opt-in: a constant countdown is the anxious
  /// kind of reminder, not the motivating kind.
  bool get showSeconds => _showSeconds;

  /// Whether the home hero rotates through the time views on its own.
  bool get slideshow => _slideshow;

  WidgetUnit get widgetUnit => _widgetUnit;

  Future<void> load() async {
    _setProfile(await _store.load());
    _unit = HeroUnit.fromName(await _store.loadUnit());
    _memories = {for (final m in await _store.loadMemories()) m.week: m};
    _people = await _store.loadPeople();
    _showPeople = await _store.loadShowPeople();
    _bucket = await _store.loadBucket();
    _theme = AppTheme.fromName(await _store.loadThemeMode());
    _showSeconds = await _store.loadShowSeconds();
    _slideshow = await _store.loadSlideshow();
    _widgetUnit = WidgetUnit.fromName(await _store.loadWidgetUnit());
    notifyListeners();
    // Installs from before the bucket list: start it with the one thing.
    final intention = _profile?.intention ?? '';
    if (intention.isNotEmpty && !await _store.hasBucket()) {
      await addBucketItem(intention);
    }
    await _syncWidget();
  }

  Future<void> save(Profile profile) async {
    _setProfile(profile);
    notifyListeners();
    await _store.save(profile);
    await _syncWidget();
  }

  Future<void> update(Profile Function(Profile current) change) async {
    final current = _profile;
    if (current == null) return;
    await save(change(current));
  }

  Future<void> cycleUnit() async {
    _unit = _unit.next;
    notifyListeners();
    await _store.saveUnit(_unit.name);
  }

  /// Sets the unit the hero opens on.
  Future<void> setUnit(HeroUnit unit) async {
    _unit = unit;
    notifyListeners();
    await _store.saveUnit(unit.name);
  }

  Future<void> setShowPeople(bool value) async {
    _showPeople = value;
    notifyListeners();
    await _store.saveShowPeople(value);
  }

  /// Saves (or replaces) the memory for [memory.week]. Blank text removes it.
  Future<void> saveMemory(WeekMemory memory) async {
    final text = memory.text.trim();
    if (text.isEmpty) return removeMemory(memory.week);
    _memories = {
      ..._memories,
      memory.week: WeekMemory(
        week: memory.week,
        text: text.length > WeekMemory.maxLength
            ? text.substring(0, WeekMemory.maxLength)
            : text,
        stamp: memory.stamp,
      ),
    };
    await _saveMemories();
  }

  Future<void> removeMemory(int week) async {
    if (!_memories.containsKey(week)) return;
    _memories = Map.of(_memories)..remove(week);
    await _saveMemories();
  }

  Future<void> _saveMemories() async {
    notifyListeners();
    await _store.saveMemories(_memories.values);
    await _syncWidget();
  }

  Future<void> addPerson(Person person) => _savePeople([..._people, person]);

  Future<void> updatePerson(Person person) =>
      _savePeople([for (final p in _people) p.id == person.id ? person : p]);

  Future<void> removePerson(String id) =>
      _savePeople(_people.where((p) => p.id != id).toList());

  Future<void> _savePeople(List<Person> people) async {
    _people = people;
    notifyListeners();
    await _store.savePeople(people);
  }

  Future<void> setTheme(AppTheme theme) async {
    _theme = theme;
    notifyListeners();
    await _store.saveThemeMode(theme.name);
  }

  Future<void> setWidgetUnit(WidgetUnit unit) async {
    _widgetUnit = unit;
    notifyListeners();
    await _store.saveWidgetUnit(unit.name);
    await _syncWidget();
  }

  Future<void> setSlideshow(bool value) async {
    _slideshow = value;
    notifyListeners();
    await _store.saveSlideshow(value);
  }

  Future<void> setShowSeconds(bool value) async {
    _showSeconds = value;
    notifyListeners();
    await _store.saveShowSeconds(value);
  }

  /// Marks the one thing as done on the bucket list (adding it first if
  /// needed). Returns false when there is no one thing.
  Future<bool> completeIntention() async {
    final intention = _profile?.intention.trim() ?? '';
    if (intention.isEmpty) return false;
    await addBucketItem(intention);
    final item = _bucket
        .where((i) => i.text.toLowerCase() == intention.toLowerCase())
        .firstOrNull;
    if (item == null || item.isDone) return true;
    await toggleBucketItem(item.id);
    return true;
  }

  /// Puts the bucket list back exactly as it was (undo for [completeIntention]).
  Future<void> restoreBucket(List<BucketItem> items) => _saveBucket(items);

  Future<void> addBucketItem(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final exists = _bucket.any(
      (i) => i.text.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return;
    await _saveBucket([..._bucket, BucketItem.create(trimmed)]);
  }

  Future<void> toggleBucketItem(String id) => _saveBucket([
    for (final i in _bucket)
      if (i.id != id)
        i
      else if (i.isDone)
        i.copyWith(clearDone: true)
      else
        i.copyWith(doneAt: DateTime.now()),
  ]);

  Future<void> editBucketItem(String id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return removeBucketItem(id);
    await _saveBucket([
      for (final i in _bucket) i.id == id ? i.copyWith(text: trimmed) : i,
    ]);
  }

  Future<void> removeBucketItem(String id) =>
      _saveBucket(_bucket.where((i) => i.id != id).toList());

  /// Restores an item removed by mistake (undo).
  Future<void> restoreBucketItem(BucketItem item) async {
    if (_bucket.any((i) => i.id == item.id)) return;
    await _saveBucket([..._bucket, item]);
  }

  /// Makes a bucket-list item the "one thing" shown on home and the widget.
  Future<void> pinBucketItem(String id) async {
    final item = _bucket.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    await update((p) => p.copyWith(intention: item.text));
  }

  Future<void> _saveBucket(List<BucketItem> items) async {
    _bucket = items;
    notifyListeners();
    await _store.saveBucket(items);
  }

  Future<void> reset() async {
    _setProfile(null);
    _unit = HeroUnit.clock;
    _widgetUnit = WidgetUnit.slideshow;
    _bucket = [];
    _memories = {};
    _people = [];
    notifyListeners();
    await _store.clear();
    await _syncWidget();
  }

  void _setProfile(Profile? profile) {
    _profile = profile;
    _estimate = profile == null ? null : LifeEstimate.fromProfile(profile);
  }

  Future<void> _syncWidget() => widgets.push(
    _estimate,
    intention: _profile?.intention ?? '',
    unit: _widgetUnit.name,
    marked: _memories.keys,
  );
}
