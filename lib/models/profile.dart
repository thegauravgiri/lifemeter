enum Sex {
  female('Female'),
  male('Male'),
  unspecified('Prefer not to say');

  const Sex(this.label);
  final String label;

  static Sex fromName(String? name) => Sex.values.firstWhere(
    (s) => s.name == name,
    orElse: () => Sex.unspecified,
  );
}

/// Everything the user tells us. Stored locally only.
class Profile {
  const Profile({
    required this.birthDate,
    required this.countryCode,
    this.name = '',
    this.sex = Sex.unspecified,
    this.lifestyle = const {},
    this.intention = '',
  });

  final String name;
  final DateTime birthDate;
  final String countryCode;
  final Sex sex;

  /// Lifestyle answers: question id → option id.
  final Map<String, String> lifestyle;

  /// The one thing the user wants to do with their time.
  final String intention;

  Profile copyWith({
    String? name,
    DateTime? birthDate,
    String? countryCode,
    Sex? sex,
    Map<String, String>? lifestyle,
    String? intention,
  }) {
    return Profile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      countryCode: countryCode ?? this.countryCode,
      sex: sex ?? this.sex,
      lifestyle: lifestyle ?? this.lifestyle,
      intention: intention ?? this.intention,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'birthDate': birthDate.toIso8601String(),
    'countryCode': countryCode,
    'sex': sex.name,
    'lifestyle': lifestyle,
    'intention': intention,
  };

  static Profile? fromJson(Map<String, Object?> json) {
    final birth = DateTime.tryParse(json['birthDate'] as String? ?? '');
    final country = json['countryCode'] as String?;
    if (birth == null || country == null) return null;
    final lifestyle = json['lifestyle'];
    return Profile(
      name: json['name'] as String? ?? '',
      birthDate: birth,
      countryCode: country,
      sex: Sex.fromName(json['sex'] as String?),
      lifestyle: lifestyle is Map
          ? lifestyle.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      intention: json['intention'] as String? ?? '',
    );
  }
}
