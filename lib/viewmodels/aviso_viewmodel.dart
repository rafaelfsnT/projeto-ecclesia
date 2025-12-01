import 'dart:async';
import 'package:flutter/material.dart';
import '../models/aviso_model.dart';
import '../services/aviso_service.dart';

class AvisoViewModel with ChangeNotifier {
  final AvisoService _service = AvisoService();

  List<Aviso> _avisos = [];
  bool _isLoading = false;
  String? _error;

  List<Aviso> get avisos => _avisos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<List<Aviso>>? _subscription;
  Timer? _loadTimeout;

  // opcional: iniciar automaticamente
  AvisoViewModel({bool autoStart = true}) {
    if (autoStart) startListening();
  }

  void startListening() {
    // evita múltiplas subscrições
    _subscription?.cancel();
    _loadTimeout?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    // timeout para evitar spinner eterno
    _loadTimeout = Timer(const Duration(seconds: 7), () {
      if (_isLoading) {
        debugPrint('[AvisoViewModel] timeout: nenhum aviso recebido');
        _isLoading = false;
        notifyListeners();
      }
    });

    _subscription = _service.streamAvisos().listen((list) {
      _loadTimeout?.cancel();
      _avisos = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e, st) {
      _loadTimeout?.cancel();
      debugPrint('Erro stream avisos: $e\n$st');
      _error = e.toString();
      _avisos = [];
      _isLoading = false;
      notifyListeners();
    }, cancelOnError: true);
  }

  Future<void> create(Aviso aviso) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.createAviso(aviso);
      // normalmente o stream notificará e atualizará a lista automaticamente
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(Aviso aviso) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.updateAviso(aviso);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _service.deleteAviso(id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _loadTimeout?.cancel();
    super.dispose();
  }
}
