import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../notifier/auth_notifier.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart';

class PerfilViewModel extends ChangeNotifier {
  final AuthNotifier _authNotifier;
  final AuthService _authService;
  final UploadService _uploadService;

  bool _isLoading = false;
  String? _errorMessage;


  late TextEditingController nomeController;

  PerfilViewModel({
    required AuthNotifier authNotifier,
    required AuthService authService,
    required UploadService uploadService,
  })  : _authNotifier = authNotifier,
        _authService = authService,
        _uploadService = uploadService {

    nomeController = TextEditingController(text: _authNotifier.user?.nome ?? '');
  }


  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get user => _authNotifier.user;
  String? get profileImageUrl => user?.profileImageUrl;
  String? get uid => user?.uid;


  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }


  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }


  Future<void> handleImageUpload() async {
    if (uid == null) {
      _errorMessage = "Usuário não autenticado.";
      notifyListeners();
      return;
    }

    _setLoading(true);
    clearError();

    try {
      final newImageUrl = await _uploadService.uploadProfileImage(userId: uid!);

      if (newImageUrl != null) {
        await _authService.updateUserData(uid!, {
          'profileImageUrl': newImageUrl,
        });
      } else {

        print("Seleção de imagem cancelada.");
      }

    } catch (e) {

      _errorMessage = e.toString().contains("Exception:")
          ? e.toString().replaceAll("Exception: ", "")
          : "Erro desconhecido ao carregar a foto.";

    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile() async {
    if (uid == null) {
      _errorMessage = "Usuário não autenticado.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final nomeAtual = _authNotifier.user?.nome;
      final nomeEditado = nomeController.text.trim();

      if (nomeEditado.isEmpty) {
        _errorMessage = "O nome não pode ser vazio.";
        return false;
      }


      if (nomeEditado != nomeAtual) {
        await _authService.updateUserData(uid!, {
          'nome': nomeEditado,
        });

      }

      return true;

    } catch (e) {
      _errorMessage = "Não foi possível salvar os dados do perfil.";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeProfileImage() async {
    if (uid == null) return false;

    _setLoading(true);
    clearError();

    try {
      // Atualiza no Firestore definindo o campo como null
      await _authService.updateUserData(uid!, {
        'profileImageUrl': null,
      });

      // O AuthNotifier está escutando o Firestore, então ele vai atualizar
      // a UI automaticamente assim que o banco mudar.

      return true;
    } catch (e) {
      _errorMessage = "Erro ao remover a foto.";
      return false;
    } finally {
      _setLoading(false);
    }
  }
  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }
}