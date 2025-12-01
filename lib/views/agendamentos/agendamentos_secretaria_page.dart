import '/notifier/auth_notifier.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/utils/helpers/feedbacks_helper.dart';
import '../../app/utils/helpers/feriados_helper.dart';
import '../../widgets/missas/justificativa_dialog.dart';

class AgendamentoSecretariaPage extends StatefulWidget {
  final DateTime? dataInicial;

  const AgendamentoSecretariaPage({super.key, this.dataInicial});

  @override
  State<AgendamentoSecretariaPage> createState() =>
      _AgendamentoSecretariaPageState();
}

class _AgendamentoSecretariaPageState extends State<AgendamentoSecretariaPage> {
  late DateTime dataSelecionada;
  final FeriadosHelper _feriadosHelper = FeriadosHelper();

  final List<String> _assuntos = [
    'Intenção de Missa',
    'Agendamento de Batismo',
    'Agendamento de Casamento',
    'Confissão / Conversa com o Padre',
    'Outros Assuntos',
  ];

  @override
  void initState() {
    super.initState();
    dataSelecionada = widget.dataInicial ?? DateTime.now();
  }

  bool _isDiaSemExpediente(DateTime dia) {
    if (dia.weekday == DateTime.sunday) return true;
    if (_feriadosHelper.isFeriado(dia)) return true;
    return false;
  }

  List<TimeOfDay> _gerarHorariosDisponiveis(DateTime dia) {
    final List<TimeOfDay> horarios = [];
    if (_isDiaSemExpediente(dia)) return horarios;

    if (dia.weekday >= DateTime.monday && dia.weekday <= DateTime.friday) {
      horarios.addAll(
        _gerarIntervalos(
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
        ),
      );
      horarios.addAll(
        _gerarIntervalos(
          const TimeOfDay(hour: 13, minute: 0),
          const TimeOfDay(hour: 17, minute: 0),
        ),
      );
    } else if (dia.weekday == DateTime.saturday) {
      horarios.addAll(
        _gerarIntervalos(
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
        ),
      );
    }
    return horarios;
  }

  List<TimeOfDay> _gerarIntervalos(TimeOfDay inicio, TimeOfDay fim) {
    final List<TimeOfDay> intervalos = [];
    var horaAtual = inicio;
    while (_antes(horaAtual, fim)) {
      intervalos.add(horaAtual);
      horaAtual = TimeOfDay(
        hour: horaAtual.hour + ((horaAtual.minute + 30) ~/ 60),
        minute: (horaAtual.minute + 30) % 60,
      );
    }
    return intervalos;
  }

  bool _antes(TimeOfDay a, TimeOfDay b) {
    return a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);
  }

  Timestamp _combineDateAndTime(DateTime dia, TimeOfDay hora) {
    final dataHora = DateTime(
      dia.year,
      dia.month,
      dia.day,
      hora.hour,
      hora.minute,
    );
    return Timestamp.fromDate(dataHora);
  }

  bool _verificarHorarioPassou(TimeOfDay horaSlot) {
    final agora = DateTime.now();
    final isHoje =
        dataSelecionada.year == agora.year &&
        dataSelecionada.month == agora.month &&
        dataSelecionada.day == agora.day;
    if (!isHoje) return false;

    final minutosAgora = agora.hour * 60 + agora.minute;
    final minutosSlot = horaSlot.hour * 60 + horaSlot.minute;
    return minutosSlot < minutosAgora;
  }

  // --- DIALOGO DE CONFIRMAÇÃO (VISUAL CORRIGIDO) ---
  Future<void> _mostrarDialogoAgendamento(
    TimeOfDay hora,
    String usuarioId,
  ) async {
    String? assuntoSelecionado;
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);

    final horaFim = TimeOfDay(
      hour: hora.hour + ((hora.minute + 30) ~/ 60),
      minute: (hora.minute + 30) % 60,
    );
    final horaInicioStr = hora.format(context);
    final horaFimStr = horaFim.format(context);
    final dataFormatada = DateFormat('dd/MM/yyyy').format(dataSelecionada);
    final diaSemana = DateFormat('EEEE', 'pt_BR').format(dataSelecionada);
    final diaSemanaCap = diaSemana[0].toUpperCase() + diaSemana.substring(1);

    final bool? sucesso = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_available,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Confirmar Agendamento",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // --- CORREÇÃO VISUAL AQUI ---
                  // Usamos White com transparência (Vidro) para que o gradiente do fundo apareça
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      // Vidro semitransparente
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ), // Borda sutil
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diaSemanaCap,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  dataFormatada,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            height: 1,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Horário",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "$horaInicioStr às $horaFimStr",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Assunto do Atendimento",
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(
                        Icons.bookmark_border,
                        color: theme.colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    hint: Text(
                      "Selecione o tipo de assunto",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down_circle,
                      color: theme.colorScheme.primary,
                    ),
                    initialValue: assuntoSelecionado,
                    isExpanded: true,
                    items:
                        _assuntos
                            .map(
                              (assunto) => DropdownMenuItem(
                                value: assunto,
                                child: Text(
                                  assunto,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => assuntoSelecionado = value,
                    validator:
                        (value) =>
                            value == null ? "Selecione um assunto" : null,
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              Navigator.pop(dialogContext, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Confirmar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (sucesso == true && assuntoSelecionado != null) {
      _agendarHorario(hora, usuarioId, assuntoSelecionado!);
    }
  }

  Future<void> _agendarHorario(
    TimeOfDay hora,
    String usuarioId,
    String assunto,
  ) async {
    try {
      final slotInicio = _combineDateAndTime(dataSelecionada, hora);

      final String docId = DateFormat(
        'yyyyMMdd_HHmm',
      ).format(slotInicio.toDate());

      final docRef = FirebaseFirestore.instance
          .collection("agendamentos")
          .doc(docId); // Usa .doc(id) em vez de .add()

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          throw Exception(
            "Ops! Este horário acabou de ser reservado por outra pessoa.",
          );
        }
        transaction.set(docRef, {
          "slotInicio": slotInicio,
          "assunto": assunto,
          "usuarioId": usuarioId,
          "criadoEm": FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        FeedbackHelper.showSuccess(context, "Horário agendado com sucesso!");
      }
    } catch (e) {
      if (mounted) {
        // Mostra a mensagem amigável (remove o prefixo "Exception:")
        FeedbackHelper.showError(
          context,
          e.toString().replaceAll("Exception: ", ""),
        );
      }
    }
  }

  Query _buildQuery(DateTime dia) {
    final inicioDoDia = DateTime(dia.year, dia.month, dia.day);
    final fimDoDia = inicioDoDia.add(const Duration(days: 1, milliseconds: -1));
    return FirebaseFirestore.instance
        .collection("agendamentos")
        .where(
          "slotInicio",
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDoDia),
        )
        .where("slotInicio", isLessThanOrEqualTo: Timestamp.fromDate(fimDoDia));
  }

  Widget _buildHelperCard(int meusAgendamentosHoje) {
    final int slotsRestantes = 2 - meusAgendamentosHoje;
    final String texto =
        slotsRestantes > 0
            ? "Cada horário dura 30 minutos. Você pode agendar mais $slotsRestantes slot(s) hoje."
            : "Você atingiu o limite de 2 agendamentos por dia.";
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        title: Text(
          texto,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _cancelarAgendamento(
    String docId,
    Timestamp slotTimestamp,
  ) async {
    final dataAgendamento = slotTimestamp.toDate();
    final agora = DateTime.now();
    final limite = const Duration(hours: 24);
    final bool isLastMinute = dataAgendamento.difference(agora) < limite;

    if (agora.isAfter(dataAgendamento)) {
      // [USO DO HELPER] Lógica simplificada
      _safeAction(
        () => _executarCancelamento(
          docId,
          "Cancelado após o horário",
          slotTimestamp,
        ),
        "Agendamento removido.",
      );
      return;
    }

    String? justificativa;
    if (isLastMinute) {
      justificativa = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const JustificativaDialog(),
      );
      if (justificativa == null) return;
    } else {
      final theme = Theme.of(context);
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_mark,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Cancelar Agendamento",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Deseja realmente cancelar este agendamento?\nEsta ação liberará o horário para outros.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                () => Navigator.pop(dialogContext, false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Manter"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Sim, Cancelar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
      if (confirmar != true) return;
      justificativa = "Cancelamento com antecedência.";
    }

    // [USO DO HELPER] Executa a ação e mostra feedback
    _safeAction(
      () => _executarCancelamento(docId, justificativa, slotTimestamp),
      "Agendamento cancelado com sucesso.",
    );
  }

  // Método auxiliar privado para executar ações com feedback centralizado
  Future<void> _safeAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (mounted) {
        FeedbackHelper.showSuccess(context, successMessage);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, e.toString());
      }
    }
  }

  Future<void> _executarCancelamento(
    String docId,
    String? justificativa,
    Timestamp slot,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuário não logado.");
    final docRef = FirebaseFirestore.instance
        .collection("agendamentos")
        .doc(docId);
    final deletePromise = docRef.delete();

    if (justificativa != null && justificativa.isNotEmpty) {
      final logPromise = FirebaseFirestore.instance
          .collection("logs_cancelamentos")
          .add({
            'usuarioId': user.uid,
            'agendamentoId': docId,
            'slotCancelado': slot,
            'dataCancelamento': Timestamp.now(),
            'justificativa': justificativa,
            'tipo': 'agendamento',
          });
      await Future.wait([deletePromise, logPromise]);
    } else {
      await deletePromise;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioId = context.watch<AuthNotifier>().user?.uid;
    if (usuarioId == null) {
      return const AppScaffold(
        title: "Agendamentos",
        body: Center(child: Text("Erro: Usuário não autenticado.")),
      );
    }

    final horariosDoDia = _gerarHorariosDisponiveis(dataSelecionada);

    return AppScaffold(
      title: "Agendar Horário",
      currentIndex: 3,
      showBottomNavBar: true,
      showBackButton: widget.dataInicial != null,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final initialDate =
                dataSelecionada.isBefore(today) ? today : dataSelecionada;

            final theme = Theme.of(context); // Captura o tema atual

            final novaData = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: today,
              lastDate: today.add(const Duration(days: 90)),
              locale: const Locale('pt', 'BR'),
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      // 1. Cor do Cabeçalho e da Bolinha de seleção
                      primary: theme.colorScheme.primary,

                      // 2. Cor do Texto dentro da Bolinha e do Cabeçalho
                      onPrimary: Colors.white,

                      // 3. Cor do Fundo do Calendário (A grade de dias) -> BRANCO
                      surface: Colors.white,

                      // 4. Cor dos Dias (números 1, 2, 3...) -> PRETO
                      onSurface: Colors.black87,
                    ),

                    // Configurações específicas do DatePicker
                    datePickerTheme: DatePickerThemeData(
                      // Define o fundo do diálogo como Branco
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      // Remove tintas extras do Material 3

                      // Define a cor do cabeçalho (onde aparece a data selecionada)
                      headerBackgroundColor: theme.colorScheme.primary,
                      headerForegroundColor: Colors.white,

                      // Arredondamento das bordas
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),

                    // Botões de Cancelar/OK na cor do tema
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (novaData != null) {
              setState(() => dataSelecionada = novaData);
            }
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: Text(
                "Horários para ${DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(dataSelecionada)}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (_isDiaSemExpediente(dataSelecionada))
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 50, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Não há expediente da secretaria neste dia (Feriado ou Domingo).",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (horariosDoDia.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    "Não há horários de agendamento para este dia.",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery(dataSelecionada).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final agendados = snapshot.data!.docs;
                  final slotsOcupados =
                      agendados
                          .map((doc) => doc['slotInicio'] as Timestamp)
                          .toSet();
                  final donosDosSlots = {
                    for (var doc in agendados)
                      (doc['slotInicio'] as Timestamp):
                          doc['usuarioId'] as String,
                  };
                  final meusAgendamentosHoje =
                      agendados
                          .where((doc) => doc['usuarioId'] == usuarioId)
                          .length;
                  final bool limiteAtingido = meusAgendamentosHoje >= 2;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: horariosDoDia.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHelperCard(meusAgendamentosHoje);
                      }
                      final horarioIndex = index - 1;
                      final hora = horariosDoDia[horarioIndex];
                      final horaFim = TimeOfDay(
                        hour: hora.hour + ((hora.minute + 30) ~/ 60),
                        minute: (hora.minute + 30) % 60,
                      );
                      final horaInicioStr = hora.format(context);
                      final horaFimStr = horaFim.format(context);
                      final slotTimestamp = _combineDateAndTime(
                        dataSelecionada,
                        hora,
                      );
                      final bool estaOcupado = slotsOcupados.contains(
                        slotTimestamp,
                      );
                      final bool horarioJaPassou = _verificarHorarioPassou(
                        hora,
                      );

                      if (!estaOcupado) {
                        if (horarioJaPassou) {
                          return ListTile(
                            enabled: false,
                            leading: const Icon(
                              Icons.access_time,
                              color: Colors.grey,
                            ),
                            title: Text(
                              "$horaInicioStr - $horaFimStr",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            subtitle: const Text("Horário expirado"),
                            trailing: const ElevatedButton(
                              onPressed: null,
                              child: Text("Expirado"),
                            ),
                          );
                        }
                        return ListTile(
                          leading: Icon(
                            Icons.circle_outlined,
                            color: Colors.green[700],
                          ),
                          title: Text("$horaInicioStr - $horaFimStr"),
                          subtitle:
                              limiteAtingido
                                  ? const Text(
                                    "Limite de 2 agendamentos/dia atingido",
                                  )
                                  : const Text("Duração: 30 minutos"),
                          trailing: ElevatedButton(
                            onPressed:
                                limiteAtingido
                                    ? null
                                    : () => _mostrarDialogoAgendamento(
                                      hora,
                                      usuarioId,
                                    ),
                            child: const Text("Agendar"),
                          ),
                        );
                      } else {
                        final reservadoPor = donosDosSlots[slotTimestamp];
                        final euReservei = (reservadoPor == usuarioId);
                        return ListTile(
                          leading: Icon(
                            euReservei ? Icons.check_circle : Icons.block,
                            color:
                                euReservei
                                    ? Colors.blue[700]
                                    : Colors.grey[600],
                          ),
                          title: Text("$horaInicioStr - $horaFimStr - Ocupado"),
                          subtitle: Text(
                            euReservei
                                ? "Você reservou este horário"
                                : "Reservado por outro usuário",
                          ),
                          trailing:
                              euReservei
                                  ? OutlinedButton(
                                    onPressed: () async {
                                      final docId =
                                          agendados
                                              .firstWhere(
                                                (doc) =>
                                                    doc['slotInicio'] ==
                                                    slotTimestamp,
                                              )
                                              .id;
                                      _cancelarAgendamento(
                                        docId,
                                        slotTimestamp,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text("Cancelar"),
                                  )
                                  : null,
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
