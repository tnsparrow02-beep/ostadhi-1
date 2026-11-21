import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_helper.dart';
import 'strings.dart';
import 'widgets.dart';

bool isPhotoUrl(String photo) {
  final v = photo.trim().toLowerCase();
  return v.startsWith('http://') || v.startsWith('https://');
}

/// Lets the teacher pick a photo from the gallery and copies it into the app's private storage.
/// Returns the stored path, or null if nothing was picked.
Future<String?> pickStudentPhotoFromGallery() async {
  final shot = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1024,
  );
  if (shot == null) return null;
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'student_photos'));
  if (!await dir.exists()) await dir.create(recursive: true);
  final ext = p.extension(shot.path).isEmpty ? '.jpg' : p.extension(shot.path);
  final dest = p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
  await shot.saveTo(dest);
  return dest;
}

/// Shows a photo that is either a URL or a private file. Falls back to an icon on any error.
class StudentPhotoView extends StatelessWidget {
  final String photo;
  final double size;
  const StudentPhotoView({super.key, required this.photo, this.size = 220});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(Icons.person_rounded, size: size * 0.5, color: Colors.grey.shade500),
    );
    Widget image;
    if (photo.trim().isEmpty) {
      image = placeholder;
    } else if (isPhotoUrl(photo)) {
      image = Image.network(
        photo.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : SizedBox(width: size, height: size, child: const Center(child: CircularProgressIndicator())),
      );
    } else {
      final file = File(photo);
      image = file.existsSync()
          ? Image.file(file, width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder)
          : placeholder;
    }
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: image);
  }
}

/// Hidden by default: the photo only appears in this dialog, opened by tapping the student's name.
Future<void> showStudentPhotoDialog(BuildContext context, Student s) {
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(s.name, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudentPhotoView(photo: s.photo),
          if (s.photo.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(c.t('noPhoto'), style: TextStyle(color: Colors.grey.shade600)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('close'))),
      ],
    ),
  );
}
