import 'package:json_annotation/json_annotation.dart';

part 'res_health.g.dart';

@JsonSerializable()
class HealthRes {
  final String status;
  final Map<String, dynamic>? info;
  final Map<String, dynamic>? error;
  final Map<String, dynamic>? details;

  HealthRes(this.status, {this.info, this.error, this.details});

  factory HealthRes.fromJson(Map<String, dynamic> json) =>
      _$HealthResFromJson(json);

  Map<String, dynamic> toJson() => _$HealthResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => HealthRes.fromJson(json);
}
