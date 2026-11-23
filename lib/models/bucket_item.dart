/// One entry on the user's bucket list.
class BucketItem {
  const BucketItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.doneAt,
  });

  factory BucketItem.create(String text, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return BucketItem(
      id: at.microsecondsSinceEpoch.toRadixString(36),
      text: text.trim(),
      createdAt: at,
    );
  }

  final String id;
  final String text;
  final DateTime createdAt;

  /// When it was ticked off; null while still to do.
  final DateTime? doneAt;

  bool get isDone => doneAt != null;

  BucketItem copyWith({
    String? text,
    DateTime? doneAt,
    bool clearDone = false,
  }) {
    return BucketItem(
      id: id,
      text: text ?? this.text,
      createdAt: createdAt,
      doneAt: clearDone ? null : (doneAt ?? this.doneAt),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    if (doneAt != null) 'doneAt': doneAt!.toIso8601String(),
  };

  static BucketItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final text = json['text'];
    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (id is! String || text is! String || created == null) return null;
    return BucketItem(
      id: id,
      text: text,
      createdAt: created,
      doneAt: DateTime.tryParse(json['doneAt']?.toString() ?? ''),
    );
  }
}
