// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileRes _$FileResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FileRes', json, ($checkedConvert) {
      final val = FileRes(
        $checkedConvert('originalName', (v) => v as String),
        $checkedConvert('filename', (v) => v as String),
        $checkedConvert('path', (v) => v as String),
        $checkedConvert('url', (v) => v as String),
        $checkedConvert('size', (v) => v as num),
        $checkedConvert('mimetype', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$FileResToJson(FileRes instance) => <String, dynamic>{
  'originalName': instance.originalName,
  'filename': instance.filename,
  'path': instance.path,
  'url': instance.url,
  'size': instance.size,
  'mimetype': instance.mimetype,
};

FileUploadRes _$FileUploadResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FileUploadRes', json, ($checkedConvert) {
      final val = FileUploadRes(
        $checkedConvert('message', (v) => v as String),
        $checkedConvert(
          'file',
          (v) => FileRes.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FileUploadResToJson(FileUploadRes instance) =>
    <String, dynamic>{'message': instance.message, 'file': instance.file};
