import '../models/activity_item.dart';
import '../models/enums.dart';
import '../services/local_storage_service.dart';
import '../utils/id_generator.dart';

/// "Recent activity" feed shown on the dashboard.
class ActivityRepository {
  ActivityRepository(this._storage);

  static const int _maxItems = 100;

  final LocalStorageService _storage;

  Future<void> log(ActivityType type, [String detail = '']) async {
    final item = ActivityItem(
      id: IdGenerator.next(),
      type: type,
      detail: detail,
      createdAt: DateTime.now(),
    );
    await _storage.put(
        LocalStorageService.activitiesBox, item.id, item.toMap());

    // Keep the feed small: drop the oldest entries.
    final box = _storage.box(LocalStorageService.activitiesBox);
    if (box.length > _maxItems) {
      for (final old in _all().skip(_maxItems)) {
        await box.delete(old.id);
      }
    }
  }

  List<ActivityItem> recent({int limit = 10}) =>
      _all().take(limit).toList();

  List<ActivityItem> _all() {
    final items = _storage
        .getAll(LocalStorageService.activitiesBox)
        .map(ActivityItem.fromMap)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }
}
