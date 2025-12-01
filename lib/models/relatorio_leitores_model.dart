class EngagementReport {
  final Map<String, UserEngagementDetails> userEngagement;
  final Map<int, int> totalWeekdayEngagement; // (Este pode ser removido, pois o heatmap o substitui)
  final Map<String, int> cargoGargalos;
  final Map<String, int> horarioEngagement; // (Este pode ser removido, pois o heatmap o substitui)
  final Map<String, int> cargoTotaisCriados;

  // [NOVO] Adicione o mapa para o Heatmap Global
  final Map<String, int> totalHorarioDiaMap;

  EngagementReport({
    required this.userEngagement,
    required this.totalWeekdayEngagement,
    required this.cargoGargalos,
    required this.horarioEngagement,
    required this.cargoTotaisCriados,
    required this.totalHorarioDiaMap, // [NOVO]
  });
}

class UserEngagementDetails {
  String userName;
  int totalServices = 0;
  final Map<String, int> cargoCount = {};
  final Map<int, int> weekdayCount = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 };

  // [NOVO] Adicione o mapa para o Heatmap Pessoal
  final Map<String, int> horarioDiaMap = {};

  UserEngagementDetails({this.userName = 'Carregando...'});
}