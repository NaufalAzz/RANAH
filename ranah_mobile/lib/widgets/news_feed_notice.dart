import 'package:flutter/material.dart';

class NewsFeedNotice {
  const NewsFeedNotice._();

  static SnackBar updated() => const SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 5),
    content: Text('Berita berhasil diperbarui.'),
  );
}
