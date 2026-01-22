// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'res_signed_url.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedUrlRes _$SignedUrlResFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SignedUrlRes', json, ($checkedConvert) {
      final val = SignedUrlRes(
        $checkedConvert('url', (v) => v as String),
        expiresIn: $checkedConvert('expiresIn', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$SignedUrlResToJson(SignedUrlRes instance) =>
    <String, dynamic>{'url': instance.url, 'expiresIn': instance.expiresIn};
