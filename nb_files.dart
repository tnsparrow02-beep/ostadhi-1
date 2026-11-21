import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_helper.dart';
import 'strings.dart';
import 'widgets.dart';

class StoredFile {
  final String path;
  final int size;
  final String ext;
  const StoredFile(this.path, this.size, this.ext);
}

/// Copies files into the app's private storage (other apps cannot browse them) and removes them.
class FileStore {
  FileStore._();

  static Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'daftar_files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _safeName(String name) => name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  static Future<StoredFile> save(String section, XFile source, String displayName) async {
    final dir = Directory(p.join((await _root()).path, section));
    if (!await dir.exists()) await dir.create(recursive: true);
    final dest = p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}_${_safeName(displayName)}');
    await source.saveTo(dest);
    final size = await File(dest).length();
    final ext = p.extension(displayName).replaceFirst('.', '').toLowerCase();
    return StoredFile(dest, size, ext);
  }

  static Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {/* the record is already gone; ignore a file that cannot be removed */}
    }
  }

  /// Forgot-PIN reset: erases ALL app data (database + every stored file).
  static Future<void> wipeEverything() async {
    final paths = await DatabaseHelper.instance.wipeAllData();
    await deleteFiles(paths);
    final base = await getApplicationDocumentsDirectory();
    for (final name in ['daftar_files', 'library', 'student_photos']) {
      try {
        final d = Directory(p.join(base.path, name));
        if (await d.exists()) await d.delete(recursive: true);
      } catch (_) {/* ignore */}
    }
  }
}

const Set<String> _imageExt = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

bool isImageExt(String ext) => _imageExt.contains(ext.toLowerCase());

/// Icon + color for a file type.
({IconData icon, Color color}) fileLook(String ext) {
  final e = ext.toLowerCase();
  if (e == 'pdf') return (icon: Icons.picture_as_pdf_rounded, color: const Color(0xFFDC2626));
  if (e == 'doc' || e == 'docx' || e == 'odt') {
    return (icon: Icons.description_rounded, color: const Color(0xFF2563EB));
  }
  if (e == 'xls' || e == 'xlsx' || e == 'csv' || e == 'ods') {
    return (icon: Icons.table_chart_rounded, color: const Color(0xFF059669));
  }
  if (e == 'ppt' || e == 'pptx' || e == 'odp') {
    return (icon: Icons.slideshow_rounded, color: const Color(0xFFEA580C));
  }
  if (isImageExt(e)) return (icon: Icons.image_rounded, color: const Color(0xFF7C3AED));
  if (e == 'zip' || e == 'rar' || e == '7z') {
    return (icon: Icons.folder_zip_rounded, color: const Color(0xFF92400E));
  }
  if (e == 'mp3' || e == 'wav' || e == 'm4a' || e == 'ogg') {
    return (icon: Icons.audiotrack_rounded, color: const Color(0xFFDB2777));
  }
  if (e == 'mp4' || e == 'mkv' || e == 'avi' || e == '3gp') {
    return (icon: Icons.movie_rounded, color: const Color(0xFF0E7490));
  }
  return (icon: Icons.insert_drive_file_rounded, color: const Color(0xFF64748B));
}

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Opens a stored file: images inside the app, everything else with the phone's own viewer.
Future<void> openNodeFile(BuildContext context, NbNode node) async {
  final exists = await File(node.path).exists();
  if (!context.mounted) return;
  if (!exists) {
    showSnack(context, context.t('fileMissing'));
    return;
  }
  if (isImageExt(node.ext)) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImageViewerScreen(path: node.path, title: node.name)),
    );
    return;
  }
  final result = await OpenFilex.open(node.path);
  if (result.type != ResultType.done && context.mounted) {
    showSnack(context, context.t('fileOpenFail'));
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String path;
  final String title;
  const ImageViewerScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 6,
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
