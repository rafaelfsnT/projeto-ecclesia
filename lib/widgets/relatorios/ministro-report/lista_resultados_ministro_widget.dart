import '/widgets/relatorios/gargalo_card_widget.dart';
import '/widgets/relatorios/heat_map_widget.dart';
import '/widgets/relatorios/ministro-report/top_ministro_title.dart';
import 'package:flutter/material.dart';
import '/models/relatorio_ministro_model.dart';

class ListaResultadosMinistrosWidget extends StatelessWidget {
  final EngagementReportMinistros report;
  final Function(String) formatarCargoCallback;
  final Function(UserEngagementDetailsMinistros) onUserTap;

  const ListaResultadosMinistrosWidget({
    super.key,
    required this.report,
    required this.formatarCargoCallback,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedUsers =
        report.userEngagement.entries.toList()..sort(
          (a, b) => b.value.totalServices.compareTo(a.value.totalServices),
        );

    if (sortedUsers.isEmpty && report.cargoGargalos.isEmpty) {
      return const Center(child: Text("Nenhum dado de ministro encontrado."));
    }

    return ListView(
      children: [
        // --- Relatório 1: Top Voluntários (Clicável) ---
        Text(
          "Top Ministros (por Total de Serviços)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (sortedUsers.isEmpty)
          const Text("Nenhum ministro serviu neste período.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedUsers.length,
            itemBuilder: (context, index) {
              final entry = sortedUsers[index];
              return TopMinistroTile(
                details: entry.value,
                rank: index + 1,
                onTap: () => onUserTap(entry.value),
              );
            },
          ),

        // --- Relatório 2: Gargalos ---
        const Divider(height: 40),
        Text(
          "Vagas Ociosas (Gargalos)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _buildGargaloList(report.cargoGargalos, report.cargoTotaisCriados),

        // --- Relatório 3: Heatmap de Engajamento ---
        const Divider(height: 40),
        Text(
          "Perfil de Engajamento (Dia x Horário)",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        HeatmapWidget(
          data: report.totalHorarioDiaMap,
          baseColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  // O _buildGargaloList pode ficar aqui
  Widget _buildGargaloList(
    Map<String, int> gargaloData,
    Map<String, int> totalData,
  ) {
    if (gargaloData.isEmpty) {
      return const Text("Nenhuma vaga ociosa encontrada. Parabéns!");
    }

    final sortedGargalos =
        gargaloData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedGargalos.length,
      itemBuilder: (context, index) {
        final entry = sortedGargalos[index];
        final cargoKey = entry.key;
        final gargaloCount = entry.value;
        final totalCount = totalData[cargoKey] ?? gargaloCount;

        // [ASSUMINDO] que você tem este widget da refatoração anterior
        return GargaloCardWidget(
          cargoKey: cargoKey,
          gargaloCount: gargaloCount,
          totalCount: totalCount,
          formatarCargoCallback: formatarCargoCallback,
        );
      },
    );
  }
}
