// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileRes _$FileResFromJson(Map<String, dynamic> json) => FileRes(
  json['originalName'] as String,
  json['filename'] as String,
  json['path'] as String,
  json['url'] as String,
  json['size'] as num,
  json['mimetype'] as String,
);

Map<String, dynamic> _$FileResToJson(FileRes instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'filename': instance.filename,
  'path': instance.path,
  'url': instance.url,
  'size': instance.size,
  'mimetype': instance.mimetype,
};

FileUploadRes _$FileUploadResFromJson(Map<String, dynamic> json) =>
    FileUploadRes(
      json['message'] as String,
      FileRes.fromJson(json['file'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FileUploadResToJson(FileUploadRes instance) =>
    <String, dynamic>{'message': instance.message, 'file': instance.file};
