import 'package:json_annotation/json_annotation.dart';

part 'resource_model.g.dart';

enum ResourceType {
  @JsonValue('pdf')
  pdf,
  @JsonValue('video')
  video,
  @JsonValue('text')
  text,
}

@JsonSerializable()
class ResourceModel {
  final int id;
  final int positionId;
  final String title;
  final String? filePath;
  final ResourceType type;
  final String? url;
  final DateTime createdAt;

  ResourceModel({
    required this.id,
    required this.positionId,
    required this.title,
    this.filePath,
    required this.type,
    this.url,
    required this.createdAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) =>
      _$ResourceModelFromJson(json);
  Map<String, dynamic> toJson() => _$ResourceModelToJson(this);

  ResourceModel copyWith({
    int? id,
    int? positionId,
    String? title,
    String? filePath,
    ResourceType? type,
    String? url,
    DateTime? createdAt,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      positionId: positionId ?? this.positionId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPdf => type == ResourceType.pdf;
  bool get isVideo => type == ResourceType.video;
  bool get isText => type == ResourceType.text;
  String get displayUrl => url ?? filePath ?? '';
  bool get hasUrl =>
      (url != null && url!.isNotEmpty) ||
      (filePath != null && filePath!.isNotEmpty);
}
