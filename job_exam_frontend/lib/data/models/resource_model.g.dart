// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourceModel _$ResourceModelFromJson(Map<String, dynamic> json) =>
    ResourceModel(
      id: (json['id'] as num).toInt(),
      positionId: (json['positionId'] as num).toInt(),
      title: json['title'] as String,
      filePath: json['filePath'] as String?,
      type: $enumDecode(_$ResourceTypeEnumMap, json['type']),
      url: json['url'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ResourceModelToJson(ResourceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'positionId': instance.positionId,
      'title': instance.title,
      'filePath': instance.filePath,
      'type': _$ResourceTypeEnumMap[instance.type]!,
      'url': instance.url,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ResourceTypeEnumMap = {
  ResourceType.pdf: 'pdf',
  ResourceType.video: 'video',
  ResourceType.text: 'text',
};
