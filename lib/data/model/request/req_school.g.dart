// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GpsLocation _$GpsLocationFromJson(Map<String, dynamic> json) => GpsLocation(
  (json['lat'] as num).toDouble(),
  (json['long'] as num).toDouble(),
);

Map<String, dynamic> _$GpsLocationToJson(GpsLocation instance) =>
    <String, dynamic>{'lat': instance.lat, 'long': instance.longitude};

CreateSchoolReq _$CreateSchoolReqFromJson(Map<String, dynamic> json) =>
    CreateSchoolReq(
      json['name'] as String,
      GpsLocation.fromJson(json['gps'] as Map<String, dynamic>),
      address: json['address'] as String?,
    );

Map<String, dynamic> _$CreateSchoolReqToJson(CreateSchoolReq instance) =>
    <String, dynamic>{
      'name': instance.name,
      'gps': instance.gps,
      'address': instance.address,
    };

UpdateSchoolReq _$UpdateSchoolReqFromJson(Map<String, dynamic> json) =>
    UpdateSchoolReq(
      name: json['name'] as String?,
      gps: json['gps'] == null
          ? null
          : GpsLocation.fromJson(json['gps'] as Map<String, dynamic>),
      address: json['address'] as String?,
    );

Map<String, dynamic> _$UpdateSchoolReqToJson(UpdateSchoolReq instance) =>
    <String, dynamic>{
      'name': instance.name,
      'gps': instance.gps,
      'address': instance.address,
    };
