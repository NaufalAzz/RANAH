// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<List<String>> pickComplaintFiles() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*,video/*'
    ..multiple = true
    ..style.display = 'none';
  html.document.body?.children.add(input);
  final result = input.onChange.first.then((_) {
    return input.files?.map((file) => file.name).toList() ?? <String>[];
  });
  input.click();
  final files = await result;
  input.remove();
  return files;
}
