import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectionService extends ChangeNotifier {
  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  StreamSubscription? _listener;

  ConnectionService() {
    _init();
  }

  void _init() async {
    // Verifica o estado inicial assim que o serviço cria
    bool result = await InternetConnection().hasInternetAccess;
    _hasConnection = result;
    notifyListeners();

    // Ouve as mudanças continuamente
    _listener = InternetConnection().onStatusChange.listen((InternetStatus status) {
      bool result = status == InternetStatus.connected;
      if (_hasConnection != result) {
        _hasConnection = result;
        notifyListeners();
      }
    });
  }

  // Função para o botão "Tentar Novamente"
  Future<void> checkNow() async {
    bool result = await InternetConnection().hasInternetAccess;
    if (_hasConnection != result) {
      _hasConnection = result;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }
}