import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/countries.dart';
import '../models/bucket_item.dart';
import '../models/person.dart';
import '../models/week_memory.dart';
import '../models/profile.dart';

/// Persists the [Profile] on-device with SharedPreferences.
class ProfileStore {
  static const _profileKey = 'profile_v2';
  static const _unitKey = 'display_unit';
  static const _bucketKey = 'bucket_v1';
  static const _themeKey = 'theme_mode';
  static const _secondsKey = 'show_seconds';
  static const _slideshowKey = 'hero_slideshow';
  static const _widgetUnitKey = 'widget_unit';
  static const _memoriesKey = 'memories_v1';
  static const _peopleKey = 'people_v1';
  static const _showPeopleKey = 'show_people';

  // Keys written by the original proof-of-concept (v1).
  static const _legacyCountryKey = 'country';
  static const _legacyDobKey = 'dob';

  Future<Profile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw != null) {
      try {
        return Profile.fromJson(jsonDecode(raw) as Map<String, Object?>);
      } on FormatException {
        return null;
      }
    }
    return _migrateLegacy(prefs);
  }

  Future<void> save(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_unitKey);
    await prefs.remove(_widgetUnitKey);
    await prefs.remove(_bucketKey);
    await prefs.remove(_memoriesKey);
    await prefs.remove(_peopleKey);
    await prefs.remove(_slideshowKey);
  }

  Future<String?> loadUnit() async =>
      (await SharedPreferences.getInstance()).getString(_unitKey);

  Future<void> saveUnit(String unit) async =>
      (await SharedPreferences.getInstance()).setString(_unitKey, unit);

  Future<String?> loadThemeMode() async =>
      (await SharedPreferences.getInstance()).getString(_themeKey);

  Future<void> saveThemeMode(String mode) async =>
      (await SharedPreferences.getInstance()).setString(_themeKey, mode);

  Future<String?> loadWidgetUnit() async =>
      (await SharedPreferences.getInstance()).getString(_widgetUnitKey);

  Future<void> saveWidgetUnit(String unit) async =>
      (await SharedPreferences.getInstance()).setString(_widgetUnitKey, unit);

  Future<bool> loadSlideshow() async =>
      (await SharedPreferences.getInstance()).getBool(_slideshowKey) ?? true;

  Future<void> saveSlideshow(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_slideshowKey, value);

  Future<bool> loadShowSeconds() async =>
      (await SharedPreferences.getInstance()).getBool(_secondsKey) ?? false;

  Future<void> saveShowSeconds(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_secondsKey, value);

  Future<bool> loadShowPeople() async =>
      (await SharedPreferences.getInstance()).getBool(_showPeopleKey) ?? true;

  Future<void> saveShowPeople(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_showPeopleKey, value);

  Future<List<WeekMemory>> loadMemories() =>
      _loadList(_memoriesKey, WeekMemory.fromJson);

  Future<void> saveMemories(Iterable<WeekMemory> memories) =>
      _saveList(_memoriesKey, memories.map((m) => m.toJson()));

  Future<List<Person>> loadPeople() => _loadList(_peopleKey, Person.fromJson);

  Future<void> savePeople(Iterable<Person> people) =>
      _saveList(_peopleKey, people.map((p) => p.toJson()));

  Future<List<T>> _loadList<T>(String key, T? Function(Object?) parse) async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(parse).whereType<T>().toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _saveList(String key, Iterable<Object?> json) async =>
      (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(json.toList()),
      );

  /// False until the bucket list has been saved once.
  Future<bool> hasBucket() async =>
      (await SharedPreferences.getInstance()).containsKey(_bucketKey);

  Future<List<BucketItem>> loadBucket() async {
    final raw = (await SharedPreferences.getInstance()).getString(_bucketKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(BucketItem.fromJson).whereType<BucketItem>().toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> saveBucket(List<BucketItem> items) async =>
      (await SharedPreferences.getInstance()).setString(
        _bucketKey,
        jsonEncode(items.map((i) => i.toJson()).toList()),
      );

  /// Carries over date of birth and country from v1 installs.
  Future<Profile?> _migrateLegacy(SharedPreferences prefs) async {
    final dob = DateTime.tryParse(prefs.getString(_legacyDobKey) ?? '');
    final countryName = prefs.getString(_legacyCountryKey);
    if (dob == null || countryName == null) return null;
    final profile = Profile(
      birthDate: dob,
      countryCode: countryByName(countryName)?.code ?? worldCode,
    );
    await save(profile);
    await prefs.remove(_legacyDobKey);
    await prefs.remove(_legacyCountryKey);
    return profile;
  }
}
