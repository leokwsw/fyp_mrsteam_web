
import 'package:dio/dio.dart';

class AttendanceCheckInReq {
  final String? courseId;
  final double lat;
  final double longitude;
  final MultipartFile? photo;

  AttendanceCheckInReq(this.lat, this.longitude, {this.courseId, this.photo});

  FormData toFormData() {
    final data = <String, dynamic>{'lat': lat, 'long': longitude};
    if (courseId != null) {
      data['courseId'] = courseId;
    }
    if (photo != null) {
      data['photo'] = photo;
    }
    return FormData.fromMap(data);
  }
}
