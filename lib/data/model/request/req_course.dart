/// 重複規則類型 (僅用於本地計算，不需要 JSON 序列化)
enum RecurrenceFrequency { weekly, biweekly, monthly }

/// 重複規則 - 僅用於本地生成時間戳，不需要 JSON 序列化
class RecurrenceRuleReq {
  final RecurrenceFrequency frequency;
  final int interval; // 每 X 週/月
  final DateTime? endDate; // 重複結束日期
  final int? occurrenceCount; // 或重複次數

  RecurrenceRuleReq({
    required this.frequency,
    this.interval = 1,
    this.endDate,
    this.occurrenceCount,
  });
}

class CourseTimestampReq {
  final num start;
  final num end;

  CourseTimestampReq(this.start, this.end);

  factory CourseTimestampReq.fromJson(Map<String, dynamic> json) =>
      CourseTimestampReq(
        json['start'] as num,
        json['end'] as num,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'start': start,
        'end': end,
      };

  static fromJsonModel(Map<String, dynamic> json) =>
      CourseTimestampReq.fromJson(json);
}

class CreateCourseReq {
  final String name;
  final String overview;
  final String room;
  final List<String> files;
  final String schoolId;
  final String tutorId;
  final List<CourseTimestampReq> timestamps;
  final String subjectShortName; // 科目代碼（必填，最多 4 字符）

  CreateCourseReq(
    this.name,
    this.overview,
    this.room,
    this.files,
    this.schoolId,
    this.tutorId,
    this.timestamps,
    this.subjectShortName,
  );

  factory CreateCourseReq.fromJson(Map<String, dynamic> json) =>
      CreateCourseReq(
        json['name'] as String,
        json['overview'] as String,
        json['room'] as String,
        (json['files'] as List<dynamic>).map((e) => e as String).toList(),
        json['schoolId'] as String,
        json['tutorId'] as String,
        (json['timestamps'] as List<dynamic>)
            .map((e) => CourseTimestampReq.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['subjectShortName'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'overview': overview,
        'room': room,
        'files': files,
        'schoolId': schoolId,
        'tutorId': tutorId,
        'timestamps': timestamps.map((e) => e.toJson()).toList(),
        'subjectShortName': subjectShortName,
      };

  static fromJsonModel(Map<String, dynamic> json) =>
      CreateCourseReq.fromJson(json);
}

class UpdateCourseReq {
  final String? name;
  final String? overview;
  final String? room;
  final List<String>? files;
  final String? schoolId;
  final String? tutorId;
  final List<CourseTimestampReq>? timestamps;
  final String? subjectShortName;

  UpdateCourseReq({
    this.name,
    this.overview,
    this.room,
    this.files,
    this.schoolId,
    this.tutorId,
    this.timestamps,
    this.subjectShortName,
  });

  factory UpdateCourseReq.fromJson(Map<String, dynamic> json) =>
      UpdateCourseReq(
        name: json['name'] as String?,
        overview: json['overview'] as String?,
        room: json['room'] as String?,
        files:
            (json['files'] as List<dynamic>?)?.map((e) => e as String).toList(),
        schoolId: json['schoolId'] as String?,
        tutorId: json['tutorId'] as String?,
        timestamps: (json['timestamps'] as List<dynamic>?)
            ?.map((e) => CourseTimestampReq.fromJson(e as Map<String, dynamic>))
            .toList(),
        subjectShortName: json['subjectShortName'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'overview': overview,
        'room': room,
        'files': files,
        'schoolId': schoolId,
        'tutorId': tutorId,
        'timestamps': timestamps?.map((e) => e.toJson()).toList(),
        'subjectShortName': subjectShortName,
      };

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateCourseReq.fromJson(json);
}

/// 根據重複規則生成多個時間戳
List<CourseTimestampReq> generateRecurrenceTimestamps({
  required DateTime startDateTime,
  required DateTime endDateTime,
  required RecurrenceFrequency frequency,
  required int interval,
  DateTime? endDate,
  int? occurrenceCount,
}) {
  final timestamps = <CourseTimestampReq>[];

  DateTime currentStart = startDateTime;
  DateTime currentEnd = endDateTime;
  int occurrences = 0;

  while (true) {
    // 添加當前時間戳
    timestamps.add(CourseTimestampReq(
      currentStart.millisecondsSinceEpoch,
      currentEnd.millisecondsSinceEpoch,
    ));
    occurrences++;

    // 檢查是否達到指定次數
    if (occurrenceCount != null && occurrences >= occurrenceCount) {
      break;
    }

    // 計算下一次時間
    switch (frequency) {
      case RecurrenceFrequency.weekly:
        currentStart = currentStart.add(Duration(days: 7 * interval));
        currentEnd = currentEnd.add(Duration(days: 7 * interval));
        break;
      case RecurrenceFrequency.biweekly:
        currentStart = currentStart.add(Duration(days: 14 * interval));
        currentEnd = currentEnd.add(Duration(days: 14 * interval));
        break;
      case RecurrenceFrequency.monthly:
        // 月份相加需要特殊處理
        final nextMonth = currentStart.month + interval;
        final year = currentStart.year + (nextMonth - 1) ~/ 12;
        final month = ((nextMonth - 1) % 12) + 1;
        final day = DateTime(year, month + 1, 0).day < currentStart.day
            ? DateTime(year, month + 1, 0).day
            : currentStart.day;
        currentStart = DateTime(
            year, month, day, currentStart.hour, currentStart.minute);

        final nextMonthEnd = currentEnd.month + interval;
        final yearEnd = currentEnd.year + (nextMonthEnd - 1) ~/ 12;
        final monthEnd = ((nextMonthEnd - 1) % 12) + 1;
        final dayEnd = DateTime(yearEnd, monthEnd + 1, 0).day < currentEnd.day
            ? DateTime(yearEnd, monthEnd + 1, 0).day
            : currentEnd.day;
        currentEnd = DateTime(
            yearEnd, monthEnd, dayEnd, currentEnd.hour, currentEnd.minute);
        break;
    }

    // 檢查是否超過結束日期
    if (endDate != null && currentStart.isAfter(endDate)) {
      break;
    }

    // 安全限制：最多生成 100 個實例
    if (occurrences >= 100) {
      break;
    }
  }

  return timestamps;
}
