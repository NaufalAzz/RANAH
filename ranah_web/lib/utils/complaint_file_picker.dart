import '../services/complaint_repository.dart';

import 'complaint_file_picker_stub.dart'
    if (dart.library.html) 'complaint_file_picker_web.dart' as platform;

/// Opens the browser's image chooser and returns bytes for multipart upload.
Future<List<ComplaintAttachment>> pickComplaintFiles() =>
    platform.pickComplaintFiles();
