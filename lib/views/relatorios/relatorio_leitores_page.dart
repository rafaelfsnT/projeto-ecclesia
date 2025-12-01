import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/relatorio_leitores_model.dart';
import '../../services/leitores_pdf_generator.dart';
import '../../widgets/app/app_scaffold.dart';
import '../../widgets/relatorios/leitor-report/detalhe_usuario_modal.dart';
import '../../widgets/relatorios/leitor-report/filtros_relatorios_widget.dart';
import '../../widgets/relatorios/leitor-report/lista_resultados_leitores_widget.dart';

class RelatorioLeitoresPage extends StatefulWidget {
  const RelatorioLeitoresPage({super.key});

  @override
  State<RelatorioLeitoresPage> createState() => _RelatorioLeitoresPageState();
}

class _RelatorioLeitoresPageState extends State<RelatorioLeitoresPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  EngagementReport? _report;
  String _filtroCargo = 'todos';

  final Map<String, String> _cargoFiltroOpcoes = {
    'todos': 'Todos os Leitores',
    'leituras': 'Apenas Leituras (1ª e 2ª)',
    'salmo': 'Apenas Salmos',
    'comentarista': 'Apenas Comentaristas',
    'preces': 'Apenas Preces',
  };

  // --- LÓGICA DE SELEÇÃO DE DATA (VALIDAÇÕES) ---

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    // Data inicial não pode ser futura, nem maior que a data final atual
    final lastDateLimit = _endDate.isAfter(now) ? now : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: lastDateLimit,
      locale: const Locale('pt', 'BR'),
      helpText: 'DATA INICIAL',
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, // Não pode ser menor que o início
      lastDate: now,         // Não pode ser futura
      locale: const Locale('pt', 'BR'),
      helpText: 'DATA FINAL',
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // --- HELPER METHODS ---

  bool _isCargoDeLeitor(String key) {
    final k = key.toLowerCase();
    return k.contains('leitura') ||
        k == 'preces' ||
        k == 'salmo' ||
        k == 'comentarista';
  }

  bool _cargoMatchesFilter(String cargoKey) {
    final k = cargoKey.toLowerCase();
    switch (_filtroCargo) {
      case 'leituras':
        return k.contains('leitura');
      case 'salmo':
        return k == 'salmo';
      case 'comentarista':
        return k == 'comentarista';
      case 'preces':
        return k == 'preces';
      case 'todos':
      default:
        return _isCargoDeLeitor(cargoKey);
    }
  }

  String _formatarCargo(String cargoKey) {
    switch (cargoKey) {
      case 'comentarista':
        return 'Comentarista';
      case 'preces':
        return 'Preces';
      case 'primeiraLeitura':
        return '1ª Leitura';
      case 'segundaLeitura':
        return '2ª Leitura';
      case 'salmo':
        return 'Salmo';
      default:
        return cargoKey;
    }
  }

  String _getPeriodo(int hora) {
    if (hora < 12) return 'Manhã';
    if (hora < 18) return 'Tarde';
    return 'Noite';
  }

  String _formatarDia(int weekday) {
    const dias = {1: 'SEG', 2: 'TER', 3: 'QUA', 4: 'QUI', 5: 'SEX', 6: 'SAB', 7: 'DOM'};
    return dias[weekday] ?? '';
  }

  // --- LÓGICA DE NEGÓCIO (RELATÓRIO) ---

  Future<void> _gerarRelatorio() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A data inicial não pode ser maior que a final.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _report = null;
    });

    final startTimestamp = Timestamp.fromDate(
        DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0)
    );
    final endTimestamp = Timestamp.fromDate(
      DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
    );

    final Map<String, UserEngagementDetails> userMap = {};
    final Map<int, int> totalWeekdayMap = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final Map<String, int> cargoGargaloMap = {};
    final Map<String, int> horarioMap = {'Manhã': 0, 'Tarde': 0, 'Noite': 0};
    final Map<String, int> cargoTotaisCriadosMap = {};
    final Map<String, int> totalHorarioDiaMap = {};
    final DateTime agora = DateTime.now();

    try {
      final query = await FirebaseFirestore.instance
          .collection('missas')
          .where('dataHora', isGreaterThanOrEqualTo: startTimestamp)
          .where('dataHora', isLessThanOrEqualTo: endTimestamp)
          .get();

      for (final missaDoc in query.docs) {
        final data = missaDoc.data();
        final dataHora = (data['dataHora'] as Timestamp).toDate();

        final DateTime dataExpiracao = dataHora.add(const Duration(hours: 1));
        if (dataExpiracao.isAfter(agora)) continue;

        final escala = data['escala'] as Map<String, dynamic>? ?? {};
        final weekday = dataHora.weekday;
        final periodo = _getPeriodo(dataHora.hour);

        final diaStr = _formatarDia(weekday);
        final periodoStr = periodo.toUpperCase();
        final compositeKey = "$diaStr-$periodoStr";

        for (final entry in escala.entries) {
          final cargo = entry.key;
          final uid = entry.value;

          if (_cargoMatchesFilter(cargo)) {
            cargoTotaisCriadosMap[cargo] = (cargoTotaisCriadosMap[cargo] ?? 0) + 1;

            if (uid != null && uid is String) {
              final details = userMap.putIfAbsent(uid, () => UserEngagementDetails());
              details.totalServices++;
              details.cargoCount[cargo] = (details.cargoCount[cargo] ?? 0) + 1;
              details.weekdayCount[weekday] = (details.weekdayCount[weekday] ?? 0) + 1;
              details.horarioDiaMap[compositeKey] = (details.horarioDiaMap[compositeKey] ?? 0) + 1;

              totalHorarioDiaMap[compositeKey] = (totalHorarioDiaMap[compositeKey] ?? 0) + 1;
              totalWeekdayMap[weekday] = (totalWeekdayMap[weekday] ?? 0) + 1;
              horarioMap[periodo] = (horarioMap[periodo] ?? 0) + 1;
            } else {
              cargoGargaloMap[cargo] = (cargoGargaloMap[cargo] ?? 0) + 1;
            }
          }
        }
      }

      for (final uid in userMap.keys) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
          userMap[uid]!.userName = userDoc.exists
              ? (userDoc.data()!['nome'] ?? 'Nome não cadastrado')
              : 'Usuário Excluído';
        } catch (e) {
          userMap[uid]!.userName = 'Erro ao buscar nome';
        }
      }

      setState(() {
        _report = EngagementReport(
          userEngagement: userMap,
          totalWeekdayEngagement: totalWeekdayMap,
          cargoGargalos: cargoGargaloMap,
          horarioEngagement: horarioMap,
          cargoTotaisCriados: cargoTotaisCriadosMap,
          totalHorarioDiaMap: totalHorarioDiaMap,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao gerar relatório: $e"))
      );
    }
  }

  void _showUserDetailModal(BuildContext context, UserEngagementDetails details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => DetalheUsuarioModal(
        details: details,
        formatarCargoCallback: _formatarCargo,
      ),
    );
  }

  Future<void> _exportarPDF() async {
    if (_report == null) return;
    setState(() => _isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gerando PDF..."), duration: Duration(seconds: 2)),
    );

    try {
      final generator = LeitoresPdfGenerator(
        report: _report!,
        startDate: _startDate,
        endDate: _endDate,
        filtroCargoLabel: _cargoFiltroOpcoes[_filtroCargo]!,
        formatarCargoCallback: _formatarCargo,
      );
      await generator.generateAndOpenFile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao exportar PDF: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Relatório de Leitores",
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // [ATUALIZADO] Passa as funções com validação
            FiltrosRelatorioWidget(
              startDate: _startDate,
              endDate: _endDate,
              filtroCargo: _filtroCargo,
              cargoFiltroOpcoes: _cargoFiltroOpcoes,
              isLoading: _isLoading,
              onTapStartDate: _selectStartDate,
              onTapEndDate: _selectEndDate,
              onGerarRelatorio: _gerarRelatorio,
              onExportPDF: _exportarPDF,
              onFiltroChanged: (novoFiltro) {
                setState(() => _filtroCargo = novoFiltro);
              },
              canExport: _report != null,
            ),
            const Divider(height: 32),

            // Widget de Resultados
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _report == null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.record_voice_over, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text(
                      "Selecione um período e gere o relatório.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListaResultadosLeitoresWidget(
                report: _report!,
                filtroCargoLabel: _cargoFiltroOpcoes[_filtroCargo]!,
                formatarCargoCallback: _formatarCargo,
                onUserTap: (details) => _showUserDetailModal(context, details),
              ),
            ),
          ],
        ),
      ),
    );
  }
}