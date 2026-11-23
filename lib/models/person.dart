import 'dart:math' as math;

import '../data/countries.dart';

/// Someone the user wants more time with (the Tail End, done kindly).
class Person {
  const Person({
    required this.id,
    required this.label,
    required this.birthYear,
    required this.visitsPerYear,
  });

  factory Person.create({
    required String label,
    required int birthYear,
    required int visitsPerYear,
    DateTime? now,
  }) => Person(
    id: (now ?? DateTime.now()).microsecondsSinceEpoch.toRadixString(36),
    label: label.trim(),
    birthYear: birthYear,
    visitsPerYear: visitsPerYear,
  );

  final String id;

  /// "Mum", "Grandpa", "Sam".
  final String label;
  final int birthYear;

  /// Times a year the user sees them in person.
  final int visitsPerYear;

  Person copyWith({String? label, int? birthYear, int? visitsPerYear}) =>
      Person(
        id: id,
        label: label ?? this.label,
        birthYear: birthYear ?? this.birthYear,
        visitsPerYear: visitsPerYear ?? this.visitsPerYear,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'birthYear': birthYear,
    'visitsPerYear': visitsPerYear,
  };

  static Person? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], label = json['label'];
    final year = json['birthYear'], visits = json['visitsPerYear'];
    if (id is! String || label is! String || year is! int || visits is! int) {
      return null;
    }
    return Person(id: id, label: label, birthYear: year, visitsPerYear: visits);
  }
}

/// Years [person] can expect from now, from the same country table as the
/// user. Life expectancy at birth understates it for older people (they
/// have already come through earlier risks), so it never drops below a
/// rough conditional floor.
double personRemainingYears(
  Person person,
  CountryLifeExpectancy country,
  DateTime now,
) {
  final age = math.max(0, now.year - person.birthYear);
  final fromBirth = country.average - age;
  final floor = math.max(1.0, (95 - age) * 0.3);
  return math.max(fromBirth, floor);
}

/// round(min(their remaining years, yours) × visits a year).
int visitsLeft({
  required double personRemainingYears,
  required double userRemainingYears,
  required int visitsPerYear,
}) {
  final years = math.max(
    0.0,
    math.min(personRemainingYears, userRemainingYears),
  );
  return (years * math.max(0, visitsPerYear)).round();
}
