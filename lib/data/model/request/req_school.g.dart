// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'req_school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GpsLocation _$GpsLocationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GpsLocation', json, ($checkedConvert) {
      final val = GpsLocation(
        $checkedConvert('lat', (v) => (v as num).toDouble()),
        $checkedConvert('long', (v) => (v as num).toDouble()),
      );
      return val;
    }, fieldKeyMap: const {'longitude': 'long'});

Map<String, dynamic> _$GpsLocationToJson(GpsLocation instance) =>
    <String, dynamic>{'lat': instance.lat, 'long': instance.longitude};

CreateSchoolReq _$CreateSchoolReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateSchoolReq', json, ($checkedConvert) {
      final val = CreateSchoolReq(
        $checkedConvert('name', (v) => v as String),
        $checkedConvert(
          'gps',
          (v) => GpsLocation.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateSchoolReqToJson(CreateSchoolReq instance) =>
    <String, dynamic>{'name': instance.name, 'gps': instance.gps};

UpdateSchoolReq _$UpdateSchoolReqFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateSchoolReq', json, ($checkedConvert) {
      final val = UpdateSchoolReq(
        name: $checkedConvert('name', (v) => v as String?),
        gps: $checkedConvert(
          'gps',
          (v) => v == null
              ? null
              : GpsLocation.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UpdateSchoolReqToJson(UpdateSchoolReq instance) =>
    <String, dynamic>{'name': instance.name, 'gps': instance.gps};
