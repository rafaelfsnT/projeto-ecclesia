import 'package:cloud_functions/cloud_functions.dart';

class AdminService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<void> desativarUsuario(String uid) async {
    try {
      final callable = _functions.httpsCallable('disableUser');
      await callable.call({'uid': uid});
      // Em caso de sucesso, NÃO RETORNA NADA.
    } on FirebaseFunctionsException catch (e) {
      // Em caso de erro, LANÇA a exceção para a tela.
      throw Exception(e.message ?? 'Ocorreu um erro no servidor.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: ${e.toString()}');
    }
  }

  /// Ativa um usuário via Cloud Function.
  Future<void> ativarUsuario(String uid) async {
    try {
      final callable = _functions.httpsCallable('enableUser');
      await callable.call({'uid': uid});
      // Em caso de sucesso, NÃO RETORNA NADA.
    } on FirebaseFunctionsException catch (e) {
      // Em caso de erro, LANÇA a exceção para a tela.
      throw Exception(e.message ?? 'Ocorreu um erro no servidor.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: ${e.toString()}');
    }
  }

  /// Exclui um usuário permanentemente via Cloud Function.
  Future<void> excluirUsuario(String uid) async {
    try {
      final callable = _functions.httpsCallable('deleteUser');
      await callable.call({'uid': uid});
      // Em caso de sucesso, NÃO RETORNA NADA.
    } on FirebaseFunctionsException catch (e) {
      // Em caso de erro, LANÇA a exceção para a tela.
      throw Exception(e.message ?? 'Ocorreu um erro no servidor.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: ${e.toString()}');
    }
  }
}
