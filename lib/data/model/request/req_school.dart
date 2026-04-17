import 'package:json_annotation/json_annotation.dart';

part 'req_school.g.dart';

@JsonSerializable()
class GpsLocation {
  final double lat;
  @JsonKey(name: 'long')
  final double longitude;

  GpsLocation(this.lat, this.longitude);

  factory GpsLocation.fromJson(Map<String, dynamic> json) =>
      _$GpsLocationFromJson(json);

  Map<String, dynamic> toJson() => _$GpsLocationToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => GpsLocation.fromJson(json);
}

@JsonSerializable()
class CreateSchoolReq {
  final String name;
  final GpsLocation gps;
  final String? address;

  CreateSchoolReq(this.name, this.gps, {this.address});

  factory CreateSchoolReq.fromJson(Map<String, dynamic> json) =>
      _$CreateSchoolReqFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSchoolReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      CreateSchoolReq.fromJson(json);
}

@JsonSerializable()
class UpdateSchoolReq {
  final String? name;
  final GpsLocation? gps;
  final String? address;

  UpdateSchoolReq({this.name, this.gps, this.address});

  factory UpdateSchoolReq.fromJson(Map<String, dynamic> json) =>
      _$UpdateSchoolReqFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSchoolReqToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateSchoolReq.fromJson(json);
}
