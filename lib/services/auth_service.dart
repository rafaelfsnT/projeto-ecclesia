import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required List<String> categories,
    required String? idGrupoMusical,
    required bool isBeingCreatedByLoggedInUser,
    String? idGrupoCoordenado,
  }) async {
    if (isBeingCreatedByLoggedInUser) {
      return await _registerByAdmin(
        name: name,
        email: email,
        password: password,
        categories: categories,
        idGrupoMusical: idGrupoMusical,
        idGrupoCoordenado: idGrupoCoordenado,
      );
    } else {
      return await _registerAsPublicUser(
        name: name,
        email: email,
        password: password,
        categories: categories,
        idGrupoMusical: idGrupoMusical,
        idGrupoCoordenado: idGrupoCoordenado,
      );
    }
  }

  Future<String?> _registerByAdmin({
    required String name,
    required String email,
    required String password,
    required List<String> categories,
    required String? idGrupoMusical,
    String? idGrupoCoordenado,
  }) async {
    try {
      print("Forçando a atualização do token de autenticação...");
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return "Usuário admin não está logado (currentUser é nulo).";
      }
      await currentUser.getIdToken(true);
      print("Token atualizado com sucesso. Chamando a função...");

      final HttpsCallable callable = _functions.httpsCallable(
        'criarNovoUsuarioAdmin',
      );

      await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
        'name': name,
        'categories': categories,
        'idGrupoMusical': idGrupoMusical,
        'idGrupoCoordenado': idGrupoCoordenado,
      });

      return null;
    } on FirebaseFunctionsException catch (e) {
      print("Erro da Cloud Function: ${e.code} - ${e.message}");
      return e.message ?? "Erro ao chamar a função.";
    } catch (e) {
      print("Erro geral no AuthService: ${e.toString()}");
      return e.toString();
    }
  }

  Future<String?> _registerAsPublicUser({
    required String name,
    required String email,
    required String password,
    required List<String> categories,
    required String? idGrupoMusical,
    String? idGrupoCoordenado,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;

      if (user != null) {
        // Monta o objeto de dados
        final userData = {
          'nome': name,
          'email': email,
          'role': 'user',
          'categorias': categories,
          'ativo': true,
          'criadoEm': FieldValue.serverTimestamp(),
          'idGrupoMusical': idGrupoMusical,
        };

        // Só adiciona o campo se não for nulo (opcional, mas mantém o banco limpo)
        if (idGrupoCoordenado != null) {
          userData['idGrupoCoordenado'] = idGrupoCoordenado;
        }

        await _firestore.collection('usuarios').doc(user.uid).set(userData);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Ocorreu um erro desconhecido.";
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update(data);
    } catch (e) {
      print("Erro ao atualizar dados do usuário: $e");
      throw Exception("Não foi possível salvar as alterações.");
    }
  }
}
