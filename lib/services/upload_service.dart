import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  static const int _maxSizeBytes = 5242880; // 5 MB
  static const List<String> _formatosPermitidos = ['jpg', 'jpeg', 'png'];

  Future<String> uploadImagemEvento(String eventoId, File file) async {
    try {
      _validarFormato(file);

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref('eventos_imagens/$eventoId/$fileName');
      final TaskSnapshot snapshot = await ref.putFile(file);
      final url = await snapshot.ref.getDownloadURL();

      return url;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> uploadImagensEvento(
      String eventoId, List<File> files) async {
    final urls = <String>[];
    for (final f in files) {
      final url = await uploadImagemEvento(eventoId, f);
      urls.add(url);
    }
    return urls;
  }

  Future<String?> uploadProfileImage({required String userId}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      File imageFile = File(pickedFile.path);

      // Valida formato (jpg/png)
      _validarFormato(imageFile);

      // Comprime a imagem
      Uint8List? compressedData = await _compressImage(imageFile);
      if (compressedData == null) {
        throw Exception("Erro ao processar a imagem.");
      }

      // Verifica tamanho máximo
      if (compressedData.lengthInBytes > _maxSizeBytes) {
        throw Exception(
            "A imagem é muito grande (limite de 5MB). Tente uma imagem menor.");
      }

      // Salva no Firebase Storage
      String ext = imageFile.path.split('.').last.toLowerCase();
      String filePath = 'profile_images/$userId.$ext';
      final ref = _storage.ref().child(filePath);

      UploadTask uploadTask = ref.putData(compressedData);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print("Erro no Firebase Storage: $e");
      throw Exception("Erro ao salvar a imagem. Tente novamente.");
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;

      final result = await FlutterImageCompress.compressWithFile(
        filePath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
      );

      return result;
    } catch (e) {
      print("Erro ao comprimir imagem: $e");
      return null;
    }
  }

  // 🔒 Nova função: valida extensão da imagem
  void _validarFormato(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    if (!_formatosPermitidos.contains(ext)) {
      throw Exception(
          "Formato de imagem inválido. Use apenas JPG ou PNG.");
    }
  }
}
