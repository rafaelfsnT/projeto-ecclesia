import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/relatorio_agendamento_model.dart';
import '../../services/agendamentos_pdf_generator.dart';
import '../../widgets/app/app_scaffold.dart';
import '../../widgets/relatorios/agendamentos-report/filtros_relatorio_agendamento_widget.dart';
import '../../widgets/relatorios/agendamentos-report/lista_resultados_agendamento_widget.dart';

class RelatorioAgendamentosPage extends StatefulWidget {
  const RelatorioAgendamentosPage({super.key});

  @override
  State<RelatorioAgendamentosPage> createState() =>
      _RelatorioAgendamentosPageState();
}

class _RelatorioAgendamentosPageState extends State<RelatorioAgendamentosPage> {
  // Inicia com os últimos 30 dias por padrão
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  AgendamentoReport? _report;
  Map<String, String> _userNames = {};

  // --- LÓGICA DE SELEÇÃO DE DATA (VALIDAÇÕES) ---

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    // A data inicial não pode ser depois de hoje, nem depois da data final já selecionada
    final lastDateLimit = _endDate.isAfter(now) ? now : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: lastDateLimit,
      // TRAVA: Não permite data futura nem maior que o fim
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
      firstDate: _startDate,
      // TRAVA: Não permite ser menor que a data inicial
      lastDate: now,
      // TRAVA: Não permite data futura (amanhã em diante)
      locale: const Locale('pt', 'BR'),
      helpText: 'DATA FINAL',
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // --- LÓGICA DE NEGÓCIO (RELATÓRIO) ---

  String _getPeriodo(int hora) {
    if (hora < 12) return 'Manhã';
    if (hora < 18) return 'Tarde';
    return 'Noite';
  }

  Future<void> _gerarRelatorio() async {
    // Validação extra de segurança
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A data inicial não pode ser maior que a final."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _report = null;
      _userNames = {};
    });

    final startTimestamp = Timestamp.fromDate(
      DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0),
    );
    final endTimestamp = Timestamp.fromDate(
      DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
    );

    // ... (Resto da lógica permanece igual a que você já tinha) ...
    final Map<String, int> topAssuntos = {};
    final Map<int, int> weekdayMap = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final Map<String, int> horarioMap = {'Manhã': 0, 'Tarde': 0, 'Noite': 0};
    final Map<String, int> topHorariosMap = {};
    final Set<String> uidsParaBuscar = {};
    final List<DocumentSnapshot> docsProcessados = [];
    final DateTime agora = DateTime.now();

    try {
      Query query = FirebaseFirestore.instance
          .collection('agendamentos')
          .where('slotInicio', isGreaterThanOrEqualTo: startTimestamp)
          .where('slotInicio', isLessThanOrEqualTo: endTimestamp);

      final querySnapshot = await query.get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final slotInicio = (data['slotInicio'] as Timestamp).toDate();

        // Ignora agendamentos futuros na contagem do relatório
        if (slotInicio.isAfter(agora)) continue;

        docsProcessados.add(doc);
        // ... processamento dos dados ...
        final assunto = data['assunto'] as String? ?? 'Outros Assuntos';
        final uid = data['usuarioId'] as String;
        final weekday = slotInicio.weekday;
        final periodo = _getPeriodo(slotInicio.hour);
        final horaExata = DateFormat('HH:mm').format(slotInicio);

        topAssuntos[assunto] = (topAssuntos[assunto] ?? 0) + 1;
        weekdayMap[weekday] = (weekdayMap[weekday] ?? 0) + 1;
        horarioMap[periodo] = (horarioMap[periodo] ?? 0) + 1;
        topHorariosMap[horaExata] = (topHorariosMap[horaExata] ?? 0) + 1;
        uidsParaBuscar.add(uid);
      }

      if (uidsParaBuscar.isNotEmpty) {
        _userNames = await _fetchUserNames(uidsParaBuscar.toList());
      }

      setState(() {
        _report = AgendamentoReport(
          totalAgendamentos: docsProcessados.length,
          topAssuntos: topAssuntos,
          weekdayEngagement: weekdayMap,
          horarioEngagement: horarioMap,
          topHorariosEspecificos: topHorariosMap,
          listaCompleta: docsProcessados,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao gerar relatório: $e")));
    }
  }

  Future<Map<String, String>> _fetchUserNames(List<String> uids) async {
    final Map<String, String> names = {};
    for (int i = 0; i < uids.length; i += 30) {
      final sublist = uids.sublist(
        i,
        i + 30 > uids.length ? uids.length : i + 30,
      );
      final userQuery =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where(FieldPath.documentId, whereIn: sublist)
              .get();
      for (final userDoc in userQuery.docs) {
        names[userDoc.id] =
            (userDoc.data()['nome'] as String?) ?? 'Nome Desconhecido';
      }
    }
    return names;
  }

  Future<void> _exportarPDF() async {
    if (_report == null) return;
    setState(() => _isLoading = true);
    try {
      final generator = AgendamentosPdfGenerator(
        report: _report!,
        userNames: _userNames,
        startDate: _startDate,
        endDate: _endDate,
      );
      await generator.generateAndOpenFile();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Relatório de Agendamentos",
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // WIDGET DE FILTROS ATUALIZADO
            FiltrosRelatorioAgendamentoWidget(
              startDate: _startDate,
              endDate: _endDate,
              isLoading: _isLoading,
              // Passamos as funções de select que contêm as travas
              onTapStartDate: _selectStartDate,
              onTapEndDate: _selectEndDate,
              onGerarRelatorio: _gerarRelatorio,
              onExportPDF: _exportarPDF,
              canExport: _report != null,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // WIDGET DE RESULTADOS
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _report == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Defina o período e clique em 'Gerar Relatório'",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : ListaResultadosAgendamentoWidget(
                        report: _report!,
                        userNames: _userNames,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
