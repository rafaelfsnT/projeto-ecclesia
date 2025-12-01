// Em: lib/notifier/auth_notifier.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Classe AppUser combinando tudo
class AppUser {
  final String uid;
  final String? email;
  final String nome;
  final String role;
  final List<String> categorias;
  final String? idGrupoMusical;
  final String? profileImageUrl;
  final bool emailVerified;

  AppUser({
    required this.uid,
    required this.email,
    required this.nome,
    required this.role,
    required this.categorias,
    this.idGrupoMusical,
    this.profileImageUrl,
    required this.emailVerified,
  });
}

class AuthNotifier extends ChangeNotifier {
  AppUser? _user;
  AppUser? get user => _user;

  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isAdmin => _user?.role == 'admin';
  List<String> get categorias => _user?.categorias ?? [];
  bool get isInMusicalGroup => _user?.idGrupoMusical != null;

  bool get canAccessLeitorFeatures =>
      isAdmin ||
          categorias.contains('Leitor') ||
          categorias.contains('Ministro');

  bool get canAccessMinistroFeatures =>
      isAdmin || categorias.contains('Ministro');

  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // Cancela listener anterior
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
    } else {
      // Cria um AppUser temporário imediato
      _user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        nome: 'Carregando...',
        role: 'user',
        categorias: [],
        idGrupoMusical: null,
        profileImageUrl: null,
        emailVerified: firebaseUser.emailVerified,
      );

      // Notifica imediatamente (ex: splash/login)
      notifyListeners();

      // Inicia listener do documento do usuário
      _userDocSubscription = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen(
            (docSnapshot) {
          if (docSnapshot.exists) {
            final data = docSnapshot.data()!;
            _user = AppUser(
              uid: firebaseUser.uid,
              email: firebaseUser.email,
              nome: data['nome'] ?? 'Usuário',
              role: data['role'] ?? 'user',
              categorias: List<String>.from(data['categorias'] ?? []),
              idGrupoMusical: data['idGrupoMusical'],
              profileImageUrl: data['profileImageUrl'],
              emailVerified: firebaseUser.emailVerified,
            );
          } else {
            // Usuário sem documento no Firestore
            _user = AppUser(
              uid: firebaseUser.uid,
              email: firebaseUser.email,
              nome: 'Configurar Perfil',
              role: 'user',
              categorias: [],
              idGrupoMusical: null,
              profileImageUrl: null,
              emailVerified: firebaseUser.emailVerified,
            );
          }
          notifyListeners();
        },
        onError: (error) {
          print("Erro ao ouvir o documento do usuário: $error");
          _user = null;
          notifyListeners();
          FirebaseAuth.instance.signOut();
        },
      );
    }
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
