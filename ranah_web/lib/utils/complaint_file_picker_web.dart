import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../services/complaint_repository.dart';

Future<List<ComplaintAttachment>> pickComplaintFiles() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp'
    ..multiple = true
    ..style.display = 'none';
  web.document.body?.appendChild(input);
  try {
    final selected = await _selectFiles(input);
    final files = selected ?? const <web.File>[];
    if (files.length > 3) {
      throw const ComplaintSubmissionException('Pilih maksimal tiga foto.');
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
      final buffer = await file.arrayBuffer().toDart;
      final bytes = Uint8List.view(buffer.toDart);
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

Future<List<web.File>?> _selectFiles(web.HTMLInputElement input) async {
  final result = Completer<List<web.File>?>();
  final onChange = ((web.Event _) {
    if (!result.isCompleted) result.complete(_selectedFiles(input.files));
  }).toJS;
  final onCancel = ((web.Event _) {
    if (!result.isCompleted) result.complete(null);
  }).toJS;

  input.addEventListener('change', onChange);
  input.addEventListener('cancel', onCancel);
  input.click();
  try {
    return await result.future;
  } finally {
    input.removeEventListener('change', onChange);
    input.removeEventListener('cancel', onCancel);
  }
}

List<web.File> _selectedFiles(web.FileList? fileList) {
  if (fileList == null) return const [];
  return List<web.File?>.generate(
    fileList.length,
    fileList.item,
  ).whereType<web.File>().toList(growable: false);
}

String? _contentType(web.File file) {
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
