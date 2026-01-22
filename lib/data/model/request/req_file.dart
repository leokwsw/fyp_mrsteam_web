import 'package:dio/dio.dart';

class UploadFileReq {
  final MultipartFile file;

  UploadFileReq(this.file);

  FormData toFormData() => FormData.fromMap({'file': file});
}
