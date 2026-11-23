/// A short memory pinned to one week of life.
class WeekMemory {
  const WeekMemory({required this.week, required this.text, this.stamp});

  /// Longest memory, in characters.
  static const maxLength = 24;

  /// 0-based week index in the life grid (year × 52 + week of year).
  final int week;
  final String text;

  /// A [WeekStamp] id, or null.
  final String? stamp;

  Map<String, Object?> toJson() => {
    'week': week,
    'text': text,
    if (stamp != null) 'stamp': stamp,
  };

  static WeekMemory? fromJson(Object? json) {
    if (json is! Map) return null;
    final week = json['week'], text = json['text'];
    if (week is! int || text is! String) return null;
    final stamp = json['stamp'];
    return WeekMemory(
      week: week,
      text: text,
      stamp: stamp is String ? stamp : null,
    );
  }
}
