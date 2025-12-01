import 'package:flutter/material.dart';
import '../models/liturgia_model.dart';
import '../services/liturgia_service.dart';

class LiturgiaViewModel extends ChangeNotifier {
  final _service = LiturgiaService();

  Liturgia? _liturgia;
  String? _erro;
  bool _loading = false;
  DateTime? _dataSelecionada;

  Liturgia? get liturgia => _liturgia;
  String? get erro => _erro;
  bool get loading => _loading;
  DateTime? get dataSelecionada => _dataSelecionada;

  Future<void> carregarLiturgia({DateTime? data}) async {
    _loading = true;
    _erro = null;
    _dataSelecionada = data;
    notifyListeners();

    try {
      _liturgia = await _service.fetchLiturgia(data: data);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
