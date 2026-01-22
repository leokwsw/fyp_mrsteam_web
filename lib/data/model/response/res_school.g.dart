// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolGpsRes _$SchoolGpsResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SchoolGpsRes', json, ($checkedConvert) {
      final val = SchoolGpsRes(
        $checkedConvert('lat', (v) => (v as num).toDouble()),
        $checkedConvert('long', (v) => (v as num).toDouble()),
      );
      return val;
    }, fieldKeyMap: const {'longitude': 'long'});

Map<String, dynamic> _$SchoolGpsResToJson(SchoolGpsRes instance) =>
    <String, dynamic>{'lat': instance.lat, 'long': instance.longitude};

SchoolRes _$SchoolResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SchoolRes', json, ($checkedConvert) {
      final val = SchoolRes(
        $checkedConvert('name', (v) => v as String),
        $checkedConvert(
          'gps',
          (v) => SchoolGpsRes.fromJson(v as Map<String, dynamic>),
        ),
        id: $checkedConvert('_id', (v) => v as String?),
        isDeleted: $checkedConvert('isDeleted', (v) => v as bool?),
        createdAt: $checkedConvert('createdAt', (v) => v as String?),
        updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'id': '_id'});

Map<String, dynamic> _$SchoolResToJson(SchoolRes instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'gps': instance.gps,
  'isDeleted': instance.isDeleted,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

SchoolListRes _$SchoolListResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SchoolListRes', json, ($checkedConvert) {
      final val = SchoolListRes(
        $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SchoolRes.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('page', (v) => (v as num).toInt()),
        $checkedConvert('limit', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$SchoolListResToJson(SchoolListRes instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'pages': instance.pages,
    };
