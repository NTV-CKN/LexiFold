import 'package:lexifold/data/enums/sync_option.dart';

class StudySetData {
  final String id;
  final String title;
  final String? subDescription;
  final bool isPublic;
  final String sourceLanguage;
  final String targetLanguage;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudySetData({
    required this.id,
    required this.title,
    this.subDescription,
    this.isPublic = false,
    this.sourceLanguage = 'en',
    this.targetLanguage = 'vi',
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  StudySetData copyWith({
    String? id,
    String? title,
    String? subDescription,
    bool? isPublic,
    String? sourceLanguage,
    String? targetLanguage,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudySetData(
      id: id ?? this.id,
      title: title ?? this.title,
      subDescription: subDescription ?? this.subDescription,
      isPublic: isPublic ?? this.isPublic,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StudySetData.fromData(Map<String, dynamic> data) {
    return StudySetData(
      id: data['id'] as String,
      title: data['title'] as String,
      subDescription: data['subDescription'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
      sourceLanguage: data['sourceLanguage'] as String? ?? 'en',
      targetLanguage: data['targetLanguage'] as String? ?? 'vi',
      syncStatus:
          data['syncStatus'] as String? ??
          SyncOption.pending_created.typeName,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.parse(data['createdAt'] as String),
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt'] as DateTime
          : DateTime.parse(data['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subDescription': subDescription,
      'isPublic': isPublic,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
