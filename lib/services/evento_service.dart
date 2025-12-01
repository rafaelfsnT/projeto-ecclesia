// lib/services/evento_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/evento_model.dart';

class EventoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'eventos';

  // -----------------------
  // STREAM / READ
  // -----------------------

  /// Stream em tempo real para o ViewModel / UI
  Stream<List<Evento>> get eventos {
    return _firestore
        .collection(_collection)
        .orderBy('dataHora', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Evento.fromMap(doc.data(), doc.id)).toList());
  }

  /// Busca uma vez (não em tempo real)
  Future<List<Evento>> getEventos() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('dataHora', descending: false)
        .get();

    return snapshot.docs.map((doc) => Evento.fromMap(doc.data(), doc.id)).toList();
  }

  // -----------------------
  // CREATE
  // -----------------------

  /// Cria documento do evento sem imagens e retorna eventId
  Future<String> criarEventoSemImagens(Evento evento) async {
    try {
      await _validarEvento(evento, isUpdate: false);

      final docRef = await _firestore.collection(_collection).add(_buildMapFromEvento(evento));
      return docRef.id;
    } catch (e) {
      print('EventoService.criarEventoSemImagens erro: $e');
      rethrow;
    }
  }

  /// Cria evento e realiza upload de imagens (se houver). Retorna eventId.
  /// - Primeiro cria o documento (sem imagens), pega o ID, faz upload das imagens
  ///   e atualiza o documento com a lista de URLs das imagens.
  Future<String> criarEventoComImagens(Evento evento, List<File> imagens) async {
    try {
      // validação
      await _validarEvento(evento, isUpdate: false);

      // cria doc sem imagens
      final docRef = await _firestore.collection(_collection).doc();
      evento.id = docRef.id; // opcional: mantém id no objeto
      final map = _buildMapFromEvento(evento);

      await docRef.set(map);

      if (imagens.isNotEmpty) {
        final urls = await uploadImagensEvento(imagens, docRef.id);
        await docRef.update({'imageUrls': urls});
      }

      return docRef.id;
    } catch (e) {
      print('EventoService.criarEventoComImagens erro: $e');
      rethrow;
    }
  }

  /// Método simples/compatível: cria usando Evento e (opcional) lista de URLs já obtidas
  Future<void> criarEvento(Evento evento, {List<String>? imageUrls}) async {
    try {
      await _validarEvento(evento, isUpdate: false);
      final docRef = _firestore.collection(_collection).doc();
      evento.id = docRef.id;
      final map = _buildMapFromEvento(evento);
      if (imageUrls != null && imageUrls.isNotEmpty) map['imageUrls'] = imageUrls;
      await docRef.set(map);
    } catch (e) {
      print('EventoService.criarEvento erro: $e');
      rethrow;
    }
  }

  // -----------------------
  // UPLOAD IMAGENS
  // -----------------------

  /// Upload de múltiplas imagens para um eventId — retorna lista de URLs
  Future<List<String>> uploadImagensEvento(List<File> imagens, String eventId) async {
    final List<String> urls = [];
    for (int i = 0; i < imagens.length; i++) {
      final imagem = imagens[i];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${i}_${imagem.path.split('/').last}';
      final ref = _storage.ref().child('eventos_imagens/$eventId/$fileName');

      final uploadTaskSnapshot = await ref.putFile(imagem);
      final downloadUrl = await uploadTaskSnapshot.ref.getDownloadURL();
      urls.add(downloadUrl);
    }
    return urls;
  }

  /// Upload single image (útil em outras rotas). Se eventId for null, salva em unsorted.
  Future<String> uploadImagemEvento(File imagem, {String? eventId}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${timestamp}_${imagem.path.split('/').last}';
    final path = eventId != null ? 'eventos_imagens/$eventId/$fileName' : 'eventos_imagens/unsorted/$fileName';
    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(imagem);
    return await snapshot.ref.getDownloadURL();
  }

  // -----------------------
  // UPDATE
  // -----------------------

  /// Atualizar um evento usando o objeto Evento (com validação)
  /// Atualiza também imageUrls se fornecido.
  Future<void> atualizarEvento(Evento evento, {List<String>? imageUrls}) async {
    if (evento.id == null) {
      throw Exception('Evento sem ID não pode ser atualizado.');
    }
    try {
      await _validarEvento(evento, isUpdate: true);
      final map = _buildMapFromEvento(evento);
      if (imageUrls != null) map['imageUrls'] = imageUrls;
      await _firestore.collection(_collection).doc(evento.id).update(map);
    } catch (e) {
      print('EventoService.atualizarEvento erro: $e');
      rethrow;
    }
  }

  /// Atualizar campos arbitrários (útil para updates parciais)
  Future<void> atualizarEventoCampos(String eventId, Map<String, dynamic> campos) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update(campos);
    } catch (e) {
      print('EventoService.atualizarEventoCampos erro: $e');
      rethrow;
    }
  }

  // -----------------------
  // DELETE
  // -----------------------

  /// Deletar evento (Firestore) e tenta deletar arquivos no Storage (pasta do evento)
  Future<void> deletarEvento(String id) async {
    try {
      // tenta deletar arquivos na pasta do evento no Storage
      try {
        final listRef = _storage.ref().child('eventos_imagens/$id');
        final result = await listRef.listAll();
        for (final item in result.items) {
          await item.delete();
        }
      } catch (e) {
        // pode falhar se a pasta não existir ou permissão; apenas loga
        print('Aviso ao deletar imagens do Storage: $e');
      }

      // deleta o documento
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('EventoService.deletarEvento erro: $e');
      rethrow;
    }
  }

  /// Deletar apenas uma imagem por URL (usa refFromURL)
  Future<void> deletarImagemPorUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Erro ao deletar imagem por URL: $e');
      rethrow;
    }
  }

  // -----------------------
  // HELPERS PRIVADOS
  // -----------------------

  /// Monta o Map que será salvo no Firestore a partir do Evento
  Map<String, dynamic> _buildMapFromEvento(Evento evento) {
    final titulo = evento.titulo.trim();
    final descricao = evento.descricao.trim();
    final local = evento.local.trim();

    final map = <String, dynamic>{
      'titulo': titulo,
      'descricao': descricao,
      'local': local,
      'dataHora': Timestamp.fromDate(evento.dataHora),
    };

    if (evento.imageUrls != null && evento.imageUrls!.isNotEmpty) {
      map['imageUrls'] = evento.imageUrls;
    }
    // outros campos opcionais do modelo podem ser adicionados aqui

    return map;
  }

  /// Valida campos essenciais. isUpdate: permite que o próprio documento exista sem considerar duplicação
  Future<void> _validarEvento(Evento evento, {bool isUpdate = false}) async {
    final titulo = evento.titulo.trim();
    final descricao = evento.descricao.trim();
    final local = evento.local.trim();

    if (titulo.isEmpty) {
      throw Exception('Título não pode ser vazio.');
    }
    if (descricao.isEmpty) {
      throw Exception('Descrição não pode ser vazia.');
    }
    if (local.isEmpty) {
      throw Exception('Local não pode ser vazio.');
    }
    if (evento.dataHora.isBefore(DateTime.now())) {
      throw Exception('Data/Hora não pode estar no passado.');
    }

    // Se precisar validar duplicidade por título/data, pode-se adicionar aqui.
    // isUpdate pode ser usado para ignorar o próprio documento.
  }
}
