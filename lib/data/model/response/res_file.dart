import 'package:json_annotation/json_annotation.dart';

part 'res_file.g.dart';

@JsonSerializable()
class FileRes {
  final String originalName;
  final String filename;
  final String path;
  final String url;
  final num size;
  final String mimetype;

  FileRes(
    this.originalName,
    this.filename,
    this.path,
    this.url,
    this.size,
    this.mimetype,
  );

  factory FileRes.fromJson(Map<String, dynamic> json) =>
      _$FileResFromJson(json);

  Map<String, dynamic> toJson() => _$FileResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => FileRes.fromJson(json);
}

@JsonSerializable()
class FileUploadRes {
  final String message;
  final FileRes file;

  FileUploadRes(this.message, this.file);

  factory FileUploadRes.fromJson(Map<String, dynamic> json) =>
      _$FileUploadResFromJson(json);

  Map<String, dynamic> toJson() => _$FileUploadResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      FileUploadRes.fromJson(json);
}
