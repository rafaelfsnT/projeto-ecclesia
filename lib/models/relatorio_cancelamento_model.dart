import 'package:cloud_firestore/cloud_firestore.dart';

/// Armazena os dados processados do relatório de cancelamentos.
class CancelamentoReport {
  final int totalCancelamentos;
  final int totalUltimaHora;

  // Mapas para os gráficos
  // ex: {'Doença': 5, 'Emergência': 3}
  final Map<String, int> topMotivos;

  // ex: {'uid_do_jose': 4, 'uid_da_maria': 2}
  final Map<String, int> topUsuarios;

  // Lista de todos os documentos para a tabela de detalhes
  final List<DocumentSnapshot> listaCompleta;

  CancelamentoReport({
    required this.totalCancelamentos,
    required this.totalUltimaHora,
    required this.topMotivos,
    required this.topUsuarios,
    required this.listaCompleta,
  });
}
