import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/data/countries.dart';
import 'package:lifemeter/models/person.dart';
import 'package:lifemeter/services/profile_store.dart';
import 'package:lifemeter/services/widget_sync.dart';
import 'package:lifemeter/state/life_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('visits left = round(min(theirs, yours) x visits a year)', () {
    expect(
      visitsLeft(
        personRemainingYears: 11.6,
        userRemainingYears: 37,
        visitsPerYear: 4,
      ),
      46,
    );
    expect(
      visitsLeft(
        personRemainingYears: 40,
        userRemainingYears: 10.2,
        visitsPerYear: 2,
      ),
      20,
    );
    expect(
      visitsLeft(
        personRemainingYears: -1,
        userRemainingYears: 10,
        visitsPerYear: 4,
      ),
      0,
    );
  });

  test('remaining years never drop to nothing for older people', () {
    final nepal = countryByCode('NP');
    final now = DateTime(2026, 6, 1);
    final mum = Person.create(label: 'Mum', birthYear: 1968, visitsPerYear: 4);
    expect(
      personRemainingYears(mum, nepal, now),
      closeTo(nepal.average - 58, 0.01),
    );
    final elder = Person.create(
      label: 'Grandpa',
      birthYear: 1936,
      visitsPerYear: 1,
    );
    expect(personRemainingYears(elder, nepal, now), greaterThan(1));
  });

  test('people persist, update, hide and clear', () async {
    SharedPreferences.setMockInitialValues({});
    final c = LifeController(ProfileStore(), WidgetSync());
    await c.load();
    final mum = Person.create(label: 'Mum', birthYear: 1968, visitsPerYear: 4);
    await c.addPerson(mum);
    await c.updatePerson(mum.copyWith(visitsPerYear: 6));
    await c.setShowPeople(false);

    final again = LifeController(ProfileStore(), WidgetSync());
    await again.load();
    expect(again.people.single.visitsPerYear, 6);
    expect(again.showPeople, isFalse);
    await again.removePerson(mum.id);
    expect(again.people, isEmpty);
  });
}
