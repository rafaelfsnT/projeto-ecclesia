// lib/services/evento_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/evento_model.dart';

class EventoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'eventos';

  Stream<List<Evento>> get eventos {
    return _firestore
        .collection(_collection)
        .orderBy('dataHora', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Evento.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<Evento>> getEventos() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('dataHora', descending: false)
        .get();

    return snapshot.docs.map((doc) => Evento.fromMap(doc.data(), doc.id)).toList();
  }

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

  Future<String> uploadImagemEvento(File imagem, {String? eventId}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${timestamp}_${imagem.path.split('/').last}';
    final path = eventId != null ? 'eventos_imagens/$eventId/$fileName' : 'eventos_imagens/unsorted/$fileName';
    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(imagem);
    return await snapshot.ref.getDownloadURL();
  }

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

  Future<void> atualizarEventoCampos(String eventId, Map<String, dynamic> campos) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update(campos);
    } catch (e) {
      print('EventoService.atualizarEventoCampos erro: $e');
      rethrow;
    }
  }

  Future<void> deletarEvento(String id) async {
    try {
      // 1. Buscar o documento PRIMEIRO para pegar as URLs das imagens
      final docSnapshot = await _firestore.collection(_collection).doc(id).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();

        // Verifica se existem imagens cadastradas
        if (data != null && data.containsKey('imageUrls')) {
          // Converte dinamicamente para lista
          final List<dynamic> urlsDynamic = data['imageUrls'];

          // 2. Itera sobre cada URL e apaga do Storage
          for (var url in urlsDynamic) {
            if (url is String && url.isNotEmpty) {
              try {
                // refFromURL pega a referência exata do arquivo, não importa a pasta
                await _storage.refFromURL(url).delete();
                print("Imagem deletada do Storage: $url");
              } catch (e) {
                // Se der erro ao apagar a imagem (ex: já não existe), apenas loga e continua
                // Não queremos impedir que o evento seja deletado só porque uma imagem falhou
                print("Aviso: Erro ao deletar imagem específica ($url): $e");
              }
            }
          }
        }
      } else {
        print("Aviso: Tentativa de deletar evento que não existe no Firestore.");
      }

      // 3. Finalmente, deleta o documento do Firestore
      await _firestore.collection(_collection).doc(id).delete();

    } catch (e) {
      print('EventoService.deletarEvento erro CRÍTICO: $e');
      rethrow;
    }
  }

  Future<void> deletarImagemPorUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Erro ao deletar imagem por URL: $e');
      rethrow;
    }
  }


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
