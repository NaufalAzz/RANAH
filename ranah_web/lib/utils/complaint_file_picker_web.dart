// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../services/complaint_repository.dart';

Future<List<ComplaintAttachment>> pickComplaintFiles() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp'
    ..multiple = true
    ..style.display = 'none';
  html.document.body?.children.add(input);
  try {
    final selected = await _selectFiles(input);
    final files = selected?.toList(growable: false) ?? const <html.File>[];
    if (files.length > 3) {
      throw const ComplaintSubmissionException(
        'Pilih maksimal tiga foto.',
      );
    }

    final attachments = <ComplaintAttachment>[];
    for (final file in files) {
      final contentType = _contentType(file);
      if (contentType == null) {
        throw const ComplaintSubmissionException(
          'Lampiran hanya boleh berupa JPG, PNG, atau WebP.',
        );
      }
      if (file.size > 5 * 1024 * 1024) {
        throw const ComplaintSubmissionException(
          'Ukuran setiap foto maksimal 5 MB.',
        );
      }
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await Future.any([reader.onLoad.first, reader.onError.first]);
      final result = reader.result;
      final bytes = switch (result) {
        Uint8List value => value,
        ByteBuffer value => value.asUint8List(),
        _ => null,
      };
      if (bytes == null) {
        throw const ComplaintSubmissionException(
          'Foto tidak dapat dibaca. Pilih kembali berkasnya.',
        );
      }
      attachments.add(
        ComplaintAttachment(
          name: file.name,
          bytes: bytes,
          contentType: contentType,
        ),
      );
    }
    return attachments;
  } finally {
    input.remove();
  }
}

Future<List<html.File>?> _selectFiles(html.FileUploadInputElement input) async {
  final result = Completer<List<html.File>?>();
  final subscription = input.onChange.listen((_) {
    if (!result.isCompleted) result.complete(input.files);
  });
  void handleCancel(html.Event _) {
    if (!result.isCompleted) result.complete(null);
  }

  // `cancel` is a browser event but isn't exposed as a typed dart:html getter
  // by the Dart SDK bundled with this Flutter project.
  input.addEventListener('cancel', handleCancel);
  input.click();
  try {
    return await result.future;
  } finally {
    input.removeEventListener('cancel', handleCancel);
    await subscription.cancel();
  }
}

String? _contentType(html.File file) {
  final type = file.type.toLowerCase();
  if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(type)) {
    return type;
  }
  final name = file.name.toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  return null;
}
