import 'package:json_annotation/json_annotation.dart';

part 'res_school.g.dart';

@JsonSerializable()
class SchoolGpsRes {
  final double lat;
  @JsonKey(name: 'long')
  final double longitude;

  SchoolGpsRes(this.lat, this.longitude);

  factory SchoolGpsRes.fromJson(Map<String, dynamic> json) =>
      _$SchoolGpsResFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolGpsResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      SchoolGpsRes.fromJson(json);
}

@JsonSerializable()
class SchoolRes {
  @JsonKey(name: '_id')
  final String? id;
  final String name;
  final SchoolGpsRes? gps;
  final String? address;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  SchoolRes(
    this.name,
    this.gps, {
    this.id,
    this.address,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolRes.fromJson(Map<String, dynamic> json) =>
      _$SchoolResFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => SchoolRes.fromJson(json);
}

@JsonSerializable()
class SchoolListRes {
  final List<SchoolRes> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  SchoolListRes(this.items, this.total, this.page, this.limit, this.pages);

  factory SchoolListRes.fromJson(Map<String, dynamic> json) =>
      _$SchoolListResFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      SchoolListRes.fromJson(json);
}
