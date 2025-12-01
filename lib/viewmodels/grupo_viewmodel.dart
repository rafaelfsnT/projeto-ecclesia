import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/grupo_service.dart';

class GrupoViewModel extends ChangeNotifier {
  final GrupoService service;
  String? id;

  bool isLoading = false;
  bool isDeleting = false;
  String? error;


  final nomeController = TextEditingController();
  final liderController = TextEditingController();
  final contatoController = TextEditingController();
  final emailController = TextEditingController();
  final observacoesController = TextEditingController();

  String status = 'Ativo';
  final List<String> statusOptions = ['Ativo', 'Inativo', 'Pausa'];

  GrupoViewModel({required this.service, this.id}) {
    if (id != null) {
      load();
    }
  }

  bool get isEditMode => id != null;

  Future<void> load() async {
    if (id == null) return;
    isLoading = true; notifyListeners();
    try {
      final snap = await service.getGrupoById(id!);
      if (!snap.exists) {
        error = 'Documento não encontrado';
      } else {
        final data = snap.data() as Map<String, dynamic>;
        nomeController.text = (data['nome'] ?? '').toString();
        liderController.text = (data['lider'] ?? '').toString();
        contatoController.text = (data['contato'] ?? '').toString();
        emailController.text = (data['email'] ?? '').toString();
        observacoesController.text = (data['observacoes'] ?? '').toString();
        status = (data['status'] ?? status).toString();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nomeController.text.trim(),
      'lider': liderController.text.trim(),
      'contato': contatoController.text.trim(),
      'email': emailController.text.trim(),
      'status': status,
      'observacoes': observacoesController.text.trim(),
      // datas manipuladas no service
    };
  }

  Future<bool> save() async {
    isLoading = true; notifyListeners();
    try {
      final data = toMap();
      if (isEditMode && id != null) {
        await service.updateGrupo(id!, data);
      } else {
        // opcional: checar duplicidade
        final exists = await service.existsByName(data['nome'] as String);
        if (exists) {
          error = 'Já existe um grupo com esse nome.';
          return false;
        }
        await service.createGrupo(data);
      }
      return true;
    } on FirebaseException catch (e) {
      error = e.message ?? e.code;
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<bool> delete() async {
    if (!isEditMode || id == null) return false;
    isDeleting = true; notifyListeners();
    try {
      await service.deleteGrupo(id!);
      return true;
    } on FirebaseException catch (e) {
      error = e.message ?? e.code;
      return false;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isDeleting = false; notifyListeners();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    liderController.dispose();
    contatoController.dispose();
    emailController.dispose();
    observacoesController.dispose();
    super.dispose();
  }
}
