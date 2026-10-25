import 'package:image_picker/image_picker.dart';

abstract interface class ComplaintMediaPicker {
  Future<List<XFile>> pickImages();
}

class GalleryComplaintMediaPicker implements ComplaintMediaPicker {
  GalleryComplaintMediaPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<XFile>> pickImages() =>
      _picker.pickMultiImage(limit: 3, imageQuality: 80, maxWidth: 1920);
}
