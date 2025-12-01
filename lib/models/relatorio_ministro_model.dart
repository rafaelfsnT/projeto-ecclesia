class EngagementReportMinistros {
  final Map<String, UserEngagementDetailsMinistros> userEngagement;
  final Map<String, int> cargoGargalos;
  final Map<String, int> cargoTotaisCriados;
  final Map<String, int> totalHorarioDiaMap;

  EngagementReportMinistros({
    required this.userEngagement,
    required this.cargoGargalos,
    required this.cargoTotaisCriados,
    required this.totalHorarioDiaMap,
  });
}

class UserEngagementDetailsMinistros {
  String userName;
  int totalServices = 0;
  final Map<String, int> horarioDiaMap = {};

  UserEngagementDetailsMinistros({this.userName = 'Carregando...'});
}