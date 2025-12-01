import 'package:cloud_firestore/cloud_firestore.dart';

class AgendamentoReport {
  final int totalAgendamentos;

  final Map<String, int> topAssuntos;
  final Map<int, int> weekdayEngagement;
  final Map<String, int> horarioEngagement;
  final Map<String, int> topHorariosEspecificos;
  final List<DocumentSnapshot> listaCompleta;

  AgendamentoReport({
    required this.totalAgendamentos,
    required this.topAssuntos,
    required this.weekdayEngagement,
    required this.horarioEngagement,
    required this.topHorariosEspecificos,
    required this.listaCompleta,
  });
}
