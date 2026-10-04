import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexifold/data/source/local/lexi_fold_database.dart';

final lexifoldDbProvider = Provider((ref) {
  final db = LexiFoldDatabase();
  ref.onDispose(db.close);

  return db;
});

final studySetsDaoProvider = Provider((ref) {
  final db = ref.read(lexifoldDbProvider);

  return db.studySetsDao;
});

final studySetMetadataDaoProvider = Provider((ref) {
  final db = ref.read(lexifoldDbProvider);

  return db.studySetMetadataDao;
});
