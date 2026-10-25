import 'package:image_picker/image_picker.dart';

class ComplaintSubmissionReceipt {
  const ComplaintSubmissionReceipt({
    required this.id,
    required this.receivedAt,
  });

  final int id;
  final DateTime receivedAt;
}

abstract interface class ComplaintApi {
  Future<ComplaintSubmissionReceipt> submitComplaint({
    required String reporterName,
    required String phoneNumber,
    required String category,
    required String location,
    required String description,
    required bool consented,
    List<XFile> attachments = const [],
  });
}

class ComplaintApiException implements Exception {
  const ComplaintApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
