/// Period life expectancy at birth, by sex.
///
/// Values are rounded approximations based on the UN World Population
/// Prospects 2024 estimates (most recent year, ~2023). Verify against the
/// latest WPP release before each store release:
/// https://population.un.org/wpp/
class CountryLifeExpectancy {
  const CountryLifeExpectancy(this.code, this.name, this.female, this.male);

  /// ISO 3166-1 alpha-2 code. `XX` is the world-average fallback.
  final String code;
  final String name;
  final double female;
  final double male;

  double get average => (female + male) / 2;

  /// Regional-indicator emoji flag built from the ISO code.
  String get flag {
    if (code == worldCode) return '🌍';
    return String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
    );
  }
}

const worldCode = 'XX';

const worldAverage = CountryLifeExpectancy(
  worldCode,
  'Somewhere else',
  75.7,
  70.8,
);

const countries = <CountryLifeExpectancy>[
  CountryLifeExpectancy('AF', 'Afghanistan', 68.0, 63.7),
  CountryLifeExpectancy('DZ', 'Algeria', 78.0, 75.5),
  CountryLifeExpectancy('AR', 'Argentina', 80.0, 73.5),
  CountryLifeExpectancy('AU', 'Australia', 85.4, 81.6),
  CountryLifeExpectancy('AT', 'Austria', 84.2, 79.4),
  CountryLifeExpectancy('BD', 'Bangladesh', 75.6, 72.4),
  CountryLifeExpectancy('BE', 'Belgium', 84.0, 79.6),
  CountryLifeExpectancy('BT', 'Bhutan', 73.5, 71.7),
  CountryLifeExpectancy('BR', 'Brazil', 79.0, 72.4),
  CountryLifeExpectancy('KH', 'Cambodia', 72.4, 67.4),
  CountryLifeExpectancy('CA', 'Canada', 84.0, 79.5),
  CountryLifeExpectancy('CL', 'Chile', 83.0, 78.0),
  CountryLifeExpectancy('CN', 'China', 81.0, 75.8),
  CountryLifeExpectancy('CO', 'Colombia', 80.0, 74.0),
  CountryLifeExpectancy('CU', 'Cuba', 80.4, 76.0),
  CountryLifeExpectancy('CZ', 'Czechia', 82.0, 76.5),
  CountryLifeExpectancy('DK', 'Denmark', 83.3, 79.6),
  CountryLifeExpectancy('EC', 'Ecuador', 80.0, 74.3),
  CountryLifeExpectancy('EG', 'Egypt', 73.9, 69.4),
  CountryLifeExpectancy('ET', 'Ethiopia', 69.4, 64.5),
  CountryLifeExpectancy('FI', 'Finland', 84.4, 79.3),
  CountryLifeExpectancy('FR', 'France', 85.7, 80.0),
  CountryLifeExpectancy('DE', 'Germany', 83.3, 78.6),
  CountryLifeExpectancy('GH', 'Ghana', 67.0, 62.8),
  CountryLifeExpectancy('GR', 'Greece', 84.0, 78.8),
  CountryLifeExpectancy('HK', 'Hong Kong', 88.0, 83.2),
  CountryLifeExpectancy('HU', 'Hungary', 79.7, 73.3),
  CountryLifeExpectancy('IS', 'Iceland', 84.5, 81.0),
  CountryLifeExpectancy('IN', 'India', 73.6, 70.4),
  CountryLifeExpectancy('ID', 'Indonesia', 73.5, 69.3),
  CountryLifeExpectancy('IR', 'Iran', 79.0, 75.1),
  CountryLifeExpectancy('IQ', 'Iraq', 74.0, 70.0),
  CountryLifeExpectancy('IE', 'Ireland', 84.4, 80.6),
  CountryLifeExpectancy('IL', 'Israel', 85.0, 81.1),
  CountryLifeExpectancy('IT', 'Italy', 85.4, 81.1),
  CountryLifeExpectancy('JP', 'Japan', 87.1, 81.1),
  CountryLifeExpectancy('KZ', 'Kazakhstan', 78.6, 70.7),
  CountryLifeExpectancy('KE', 'Kenya', 66.2, 61.1),
  CountryLifeExpectancy('LU', 'Luxembourg', 85.2, 80.9),
  CountryLifeExpectancy('MY', 'Malaysia', 78.5, 74.0),
  CountryLifeExpectancy('MX', 'Mexico', 78.0, 72.0),
  CountryLifeExpectancy('MA', 'Morocco', 77.3, 73.3),
  CountryLifeExpectancy('MM', 'Myanmar', 70.0, 63.6),
  CountryLifeExpectancy('NP', 'Nepal', 72.0, 68.8),
  CountryLifeExpectancy('NL', 'Netherlands', 83.4, 80.4),
  CountryLifeExpectancy('NZ', 'New Zealand', 84.2, 80.6),
  CountryLifeExpectancy('NG', 'Nigeria', 54.6, 53.4),
  CountryLifeExpectancy('NO', 'Norway', 84.5, 81.4),
  CountryLifeExpectancy('PK', 'Pakistan', 69.6, 65.2),
  CountryLifeExpectancy('PE', 'Peru', 80.0, 75.3),
  CountryLifeExpectancy('PH', 'Philippines', 74.5, 67.9),
  CountryLifeExpectancy('PL', 'Poland', 81.9, 74.7),
  CountryLifeExpectancy('PT', 'Portugal', 84.5, 78.8),
  CountryLifeExpectancy('QA', 'Qatar', 82.0, 80.0),
  CountryLifeExpectancy('RO', 'Romania', 79.4, 72.4),
  CountryLifeExpectancy('RU', 'Russia', 78.0, 67.6),
  CountryLifeExpectancy('SA', 'Saudi Arabia', 80.0, 76.5),
  CountryLifeExpectancy('SG', 'Singapore', 85.8, 81.6),
  CountryLifeExpectancy('ZA', 'South Africa', 64.6, 58.4),
  CountryLifeExpectancy('KR', 'South Korea', 86.4, 80.6),
  CountryLifeExpectancy('ES', 'Spain', 86.2, 81.0),
  CountryLifeExpectancy('LK', 'Sri Lanka', 79.7, 73.5),
  CountryLifeExpectancy('SE', 'Sweden', 84.8, 81.6),
  CountryLifeExpectancy('CH', 'Switzerland', 85.7, 82.0),
  CountryLifeExpectancy('TZ', 'Tanzania', 69.0, 64.9),
  CountryLifeExpectancy('TH', 'Thailand', 83.6, 76.0),
  CountryLifeExpectancy('TR', 'Türkiye', 81.3, 75.8),
  CountryLifeExpectancy('UG', 'Uganda', 66.0, 61.2),
  CountryLifeExpectancy('UA', 'Ukraine', 78.0, 68.0),
  CountryLifeExpectancy('AE', 'United Arab Emirates', 83.6, 81.5),
  CountryLifeExpectancy('GB', 'United Kingdom', 83.0, 79.2),
  CountryLifeExpectancy('US', 'United States', 81.1, 75.8),
  CountryLifeExpectancy('UZ', 'Uzbekistan', 75.4, 70.9),
  CountryLifeExpectancy('VE', 'Venezuela', 75.6, 68.3),
  CountryLifeExpectancy('VN', 'Vietnam', 79.3, 69.9),
  CountryLifeExpectancy('ZW', 'Zimbabwe', 64.0, 59.0),
  worldAverage,
];

CountryLifeExpectancy countryByCode(String? code) =>
    countries.firstWhere((c) => c.code == code, orElse: () => worldAverage);

CountryLifeExpectancy? countryByName(String name) {
  for (final c in countries) {
    if (c.name.toLowerCase() == name.toLowerCase()) return c;
  }
  return null;
}
