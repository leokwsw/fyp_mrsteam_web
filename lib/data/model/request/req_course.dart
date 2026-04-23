CourseFileReq _courseFileReqFromJsonElement(dynamic e) {
  if (e is String) {
    final path = e;
    final filename = path.split('/').last;
    return CourseFileReq(
      originalName: filename,
      filename: filename,
      path: path,
      url: '',
      size: 0,
      mimetype: 'application/octet-stream',
      isExisting: true,
    );
  }
  return CourseFileReq.fromJson(e as Map<String, dynamic>);
}

/// Recurrence rule type (local calculation only, no JSON serialization needed).
enum RecurrenceFrequency { weekly, biweekly, monthly }

/// Recurrence rule - used only to generate local timestamps, no JSON serialization needed.
class RecurrenceRuleReq {
  final RecurrenceFrequency frequency;
  final int interval; // Every X weeks/months
  final DateTime? endDate; // Recurrence end date
  final int? occurrenceCount; // Or recurrence count

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

class CourseFileReq {
  final String originalName;
  final String filename;
  final String path;
  final String url;
  final int size;
  final String mimetype;
  /// UI-only: marks file loaded from API (not sent in request payload)
  final bool isExisting;

  CourseFileReq({
    required this.originalName,
    required this.filename,
    required this.path,
    required this.url,
    required this.size,
    required this.mimetype,
    this.isExisting = false,
  });

  factory CourseFileReq.fromJson(Map<String, dynamic> json) => CourseFileReq(
        originalName: json['originalName'] as String,
        filename: json['filename'] as String,
        path: json['path'] as String,
        url: json['url'] as String,
        size: json['size'] as int,
        mimetype: json['mimetype'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'originalName': originalName,
        'filename': filename,
        'path': path,
        'url': url,
        'size': size,
        'mimetype': mimetype,
      };
}

class CreateCourseReq {
  final String name;
  final String overview;
  final String room;
  final List<CourseFileReq> files;
  final String schoolId;
  final String tutorId;
  final List<CourseTimestampReq> timestamps;
  final String subjectShortName; // Subject code (required, max 4 chars)

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
        (json['files'] as List<dynamic>).map(_courseFileReqFromJsonElement).toList(),
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
        'files': files.map((e) => e.path).toList(),
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
  final List<CourseFileReq>? files;
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
        files: (json['files'] as List<dynamic>?)
            ?.map(_courseFileReqFromJsonElement)
            .toList(),
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
        'files': files?.map((e) => e.path).toList(),
        'schoolId': schoolId,
        'tutorId': tutorId,
        'timestamps': timestamps?.map((e) => e.toJson()).toList(),
        'subjectShortName': subjectShortName,
      };

  static fromJsonModel(Map<String, dynamic> json) =>
      UpdateCourseReq.fromJson(json);
}

/// Generate multiple timestamps based on recurrence rules.
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
    // Add current timestamp.
    timestamps.add(CourseTimestampReq(
      currentStart.millisecondsSinceEpoch,
      currentEnd.millisecondsSinceEpoch,
    ));
    occurrences++;

    // Check whether target occurrence count is reached.
    if (occurrenceCount != null && occurrences >= occurrenceCount) {
      break;
    }

    // Calculate next occurrence.
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
        // Month increment needs special handling.
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

    // Check whether end date is exceeded.
    if (endDate != null && currentStart.isAfter(endDate)) {
      break;
    }

    // Safety cap: generate at most 100 instances.
    if (occurrences >= 100) {
      break;
    }
  }

  return timestamps;
}
