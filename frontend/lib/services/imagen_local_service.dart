import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImagenLocalService {
  ImagenLocalService._();
  static final ImagenLocalService instance = ImagenLocalService._();

  static const _subdir = 'chat_images';

  Future<String> guardarPersistente(XFile origen) async {
    final docs = await getApplicationDocumentsDirectory();
    final destDir = Directory('${docs.path}/$_subdir');
    if (!await destDir.exists()) await destDir.create(recursive: true);

    final ext = _extension(origen.path);
    final nombre = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final destino = File('${destDir.path}/$nombre');

    await File(origen.path).copy(destino.path);
    return destino.path;
  }

  Future<void> borrar(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  String _extension(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0 || i == path.length - 1) return '.jpg';
    return path.substring(i);
  }
}
