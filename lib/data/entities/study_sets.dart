import 'package:drift/drift.dart';

import '../model/base_class_dto.dart';

@DataClassName("StudySet", extending: BaseClassDto)
class StudySets extends Table {
  TextColumn get id => text()();

  TextColumn get title => text().withLength(min: 3, max: 60)();

  TextColumn get subDescription =>
      text().nullable().withLength(min: 5, max: 150)();

  BoolColumn get isPublic =>
      boolean().withDefault(const Constant(false))();

  TextColumn get sourceLanguage =>
      text().withDefault(const Constant("en"))();

  TextColumn get targetLanguage =>
      text().withDefault(const Constant("vi"))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
