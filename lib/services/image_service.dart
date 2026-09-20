import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Product pictures: camera / gallery -> copied into the app's private
/// `product_images` folder. Only the file NAME is stored in the database;
/// [pathOf] resolves it to the real path on the current phone.
///
/// Images never leave the phone, except inside a Google Drive backup (Part 7).
class ImageService {
  final ImagePicker _picker = ImagePicker();
  late final Directory _directory;
  int _counter = 0;

  Directory get directory => _directory;

  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _directory = Directory('${docs.path}/product_images');
    if (!await _directory.exists()) {
      await _directory.create(recursive: true);
    }
  }

  String pathOf(String fileName) => '${_directory.path}/$fileName';

  /// Takes a photo with the camera. Returns the stored file name, or null if
  /// the user cancelled. Throws on permission / camera errors.
  Future<String?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1600,
    );
    return picked == null ? null : _store(picked.path);
  }

  /// Lets the user select one or several pictures from the gallery.
  Future<List<String>> pickFromGallery() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1600,
    );
    return [for (final file in picked) await _store(file.path)];
  }

  Future<void> delete(String fileName) async {
    try {
      final file = File(pathOf(fileName));
      if (await file.exists()) await file.delete();
    } on Exception {
      // Best effort: a leftover file is harmless.
    }
  }

  Future<void> deleteAll(Iterable<String> fileNames) async {
    for (final name in fileNames) {
      await delete(name);
    }
  }

  Future<String> _store(String sourcePath) async {
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${_counter++}${_extension(sourcePath)}';
    await File(sourcePath).copy(pathOf(name));
    return name;
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || path.length - dot > 5) return '.jpg';
    return path.substring(dot).toLowerCase();
  }
}
