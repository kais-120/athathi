import 'enums.dart';
import 'model_utils.dart';

/// An entry of the "recent activity" feed.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    this.detail = '',
    required this.createdAt,
  });

  final String id;
  final ActivityType type;
  final String detail;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActivityItem.fromMap(Map<String, dynamic> map) => ActivityItem(
        id: map['id'] as String,
        type: ActivityType.fromName(map['type'] as String?),
        detail: map['detail'] as String? ?? '',
        createdAt: asDate(map['createdAt']),
      );
}
