import 'package:json_annotation/json_annotation.dart';

part 'res_success.g.dart';

@JsonSerializable()
class SuccessRes {
  final bool success;

  SuccessRes(this.success);

  factory SuccessRes.fromJson(Map<String, dynamic> json) =>
      _$SuccessResFromJson(json);

  Map<String, dynamic> toJson() => _$SuccessResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => SuccessRes.fromJson(json);
}
