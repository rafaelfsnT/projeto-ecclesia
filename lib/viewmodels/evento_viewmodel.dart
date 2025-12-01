// Em: lib/viewmodels/evento_viewmodel.dart (arquivo completo)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/evento_model.dart';
import '../services/evento_service.dart';

class EventoViewModel with ChangeNotifier {
  final EventoService _service = EventoService();

  List<Evento> _eventos = [];
  bool _isLoading = true;
  StreamSubscription<List<Evento>>? _eventosSubscription;

  List<Evento> get eventos => _eventos;
  bool get isLoading => _isLoading;

  EventoViewModel() {
    _fetchEventos();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _fetchEventos() {
    _setLoading(true);

    _eventosSubscription = _service.eventos.listen((eventos) {
      _eventos = eventos;
      _setLoading(false);
    }, onError: (error) {
      print("Erro ao buscar eventos: $error");
      _setLoading(false);
    });
  }

  // MÉTODOS DE CRIAÇÃO/ATUALIZAÇÃO
  Future<void> criarEventoComImagens(Evento evento, List<File> imagens) async {
    try {
      _setLoading(true);
      final eventId = await _service.criarEventoSemImagens(evento);
      if (imagens.isNotEmpty) {
        final urls = await _service.uploadImagensEvento(imagens, eventId);
        await _service.atualizarEventoCampos(eventId, {'imageUrls': urls});
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> atualizarEventoComNovasImagens(Evento evento, List<File> novasImagens, {List<String>? imagensExistentes}) async {
    if (evento.id == null) {
      throw Exception('Evento sem ID não pode ser atualizado.');
    }

    try {
      _setLoading(true);
      final List<String> finalUrls = imagensExistentes != null
          ? List.from(imagensExistentes)
          : (evento.imageUrls != null ? List.from(evento.imageUrls!) : []);

      if (novasImagens.isNotEmpty) {
        final uploaded = await _service.uploadImagensEvento(novasImagens, evento.id!);
        finalUrls.addAll(uploaded);
      }

      final campos = evento.toMap();
      campos['imageUrls'] = finalUrls;

      await _service.atualizarEventoCampos(evento.id!, campos);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ADICIONADO: Método para deletar imagens órfãs
  Future<void> deletarImagemPorUrl(String url) async {
    try {
      await _service.deletarImagemPorUrl(url);
    } catch (e) {
      print("Erro no VM ao deletar imagem: $e");
      // Não re-lança o erro, pois a edição do evento principal pode continuar
    }
  }

  Future<void> deletarEvento(String id) async {
    _setLoading(true);
    try {
      await _service.deletarEvento(id);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async => Future.value();

  @override
  void dispose() {
    _eventosSubscription?.cancel();
    super.dispose();
  }
}