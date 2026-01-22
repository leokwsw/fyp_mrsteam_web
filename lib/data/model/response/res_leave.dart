import 'package:json_annotation/json_annotation.dart';

part 'res_leave.g.dart';

@JsonSerializable()
class LeaveRes {
  @JsonKey(name: '_id')
  final String? id;
  final String tutorId;
  final String? courseId;
  final String reason;
  final String startDate;
  final String endDate;
  final String status;
  final String? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;

  LeaveRes(
    this.tutorId,
    this.reason,
    this.startDate,
    this.endDate,
    this.status, {
    this.id,
    this.courseId,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory LeaveRes.fromJson(Map<String, dynamic> json) =>
      _$LeaveResFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) => LeaveRes.fromJson(json);
}

@JsonSerializable()
class LeaveListRes {
  final List<LeaveRes> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  LeaveListRes(this.items, this.total, this.page, this.limit, this.pages);

  factory LeaveListRes.fromJson(Map<String, dynamic> json) =>
      _$LeaveListResFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveListResToJson(this);

  static fromJsonModel(Map<String, dynamic> json) =>
      LeaveListRes.fromJson(json);
}
