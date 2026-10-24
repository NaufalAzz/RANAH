import 'complaint_file_picker_stub.dart'
    if (dart.library.html) 'complaint_file_picker_web.dart' as platform;

/// Opens the browser's native file chooser and returns selected file names.
/// The files remain local; this application does not upload them.
Future<List<String>> pickComplaintFiles() => platform.pickComplaintFiles();
