import 'package:drift/drift.dart';
import 'package:lexifold/data/enums/paging_metadata.dart';

class StudySetPagingMetadatas extends Table {
  TextColumn get categoryKey => text().clientDefault(
    () => StudySetPagingEnum.ALL_STUDY_SET.name,
  )();

  TextColumn get nextCursorId => text().nullable()();

  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {categoryKey};
}
