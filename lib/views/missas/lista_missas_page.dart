import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../app/utils/helpers/feedbacks_helper.dart';
import '../../widgets/app/app_scaffold.dart';
import '/services/missa_service.dart';
import '/widgets/missas/editar_missaC_dialog.dart';
import '/widgets/missas/editar_missasE_dialog.dart';
import '../../widgets/admin/admin_list_action_buttons.dart';

class ListaMissasPage extends StatefulWidget {
  const ListaMissasPage({super.key});

  @override
  State<ListaMissasPage> createState() => _ListaMissasPageState();
}

class _ListaMissasPageState extends State<ListaMissasPage> {
  final MissaService missaService = MissaService();

  bool _ordemCrescente = true;
  String _filtroTipo = 'Todos';
  int _filtroAno = DateTime.now().year;
  int? _filtroMes;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  Future<void> _enviarNotificacaoAgenda() async {
    if (_filtroMes == null) {
      FeedbackHelper.showSnackBar(
        context,
        "Selecione um mês no filtro para enviar o aviso.",
        isError: true,
      );
      return;
    }

    final nomeMes = DateFormat('MMMM', 'pt_BR').format(DateTime(_filtroAno, _filtroMes!));
    final nomeMesCapitalizado = "${nomeMes[0].toUpperCase()}${nomeMes.substring(1)}";

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final inicioMes = DateTime(_filtroAno, _filtroMes!, 1);
      final fimMes = DateTime(_filtroAno, _filtroMes! + 1, 0, 23, 59, 59);

      final snapshotChecagem = await FirebaseFirestore.instance
          .collection('missas')
          .where('dataHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(fimMes))
          .limit(1)
          .get();

      // Fecha o loading usando o Root Navigator
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (snapshotChecagem.docs.isEmpty) {
        if (mounted) {
          FeedbackHelper.showSnackBar(
            context,
            "Não há missas cadastradas em $nomeMesCapitalizado de $_filtroAno para notificar.",
            isError: true,
          );
        }
        return;
      }

    } catch (e) {
      // Garante o fechamento do loading em caso de erro
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) FeedbackHelper.showError(context, "Erro ao verificar missas: $e");
      return;
    }

    // 3. Confirmação
    if (!mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notificar Agenda"),
        content: Text("Deseja enviar uma notificação para todos os usuários informando que a agenda de $nomeMesCapitalizado de $_filtroAno está disponível?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Enviar Agora")),
        ],
      ),
    );

    if (confirmar != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enviando notificações...")));
    }

    try {
      await missaService.notificarAgendaMensal(nomeMesCapitalizado, _filtroAno);
      if (mounted) FeedbackHelper.showSuccess(context, "Aviso enviado com sucesso!");
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, "Erro: $e");
    }
  }

  List<QueryDocumentSnapshot> _aplicarFiltros(
    List<QueryDocumentSnapshot> docs,
  ) {
    var listaFiltrada =
        docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final dataHora = (data['dataHora'] as Timestamp).toDate();

          // 1. Filtro de Tipo
          if (_filtroTipo != 'Todos') {
            final tipoDoc = (data['tipo'] ?? 'comum').toString().toLowerCase();
            if (tipoDoc != _filtroTipo.toLowerCase()) return false;
          }

          // 2. Filtro de Ano (Obrigatório ter um ano selecionado)
          if (dataHora.year != _filtroAno) {
            return false;
          }

          // 3. Filtro de Mês (Opcional)
          if (_filtroMes != null) {
            if (dataHora.month != _filtroMes) {
              return false;
            }
          }

          return true;
        }).toList();

    // Ordenação
    if (!_ordemCrescente) {
      listaFiltrada = listaFiltrada.reversed.toList();
    }

    return listaFiltrada;
  }

  Future<void> excluirMissa(
    BuildContext context,
    String id,
    String missaNome,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Confirmar exclusão"),
            content: Text('Deseja realmente excluir a missa "$missaNome"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Excluir"),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection("missas").doc(id).delete();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Missa excluída!")));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erro: $e")));
      }
    }
  }

  Future<void> excluirTodasMissas(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("ATENÇÃO PERIGO"),
            content: const Text(
              "Isso apagará TODAS as missas do sistema. Tem certeza?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("APAGAR TUDO"),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await missaService.deleteAllMissas();
    }
  }

  void _showAddMissaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Nova Missa Comum'),
                onTap: () {
                  Navigator.pop(bc);
                  context.push('/createMissa');
                },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Nova Missa Especial'),
                onTap: () {
                  Navigator.pop(bc);
                  context.push('/createMissaE');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> editarMissaGeneric(
    BuildContext context,
    DocumentSnapshot missa,
    bool isEspecial,
  ) async {
    final bool? salvo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) =>
              isEspecial
                  ? EditarMissaEspecialDialog(missa: missa)
                  : EditarMissaComumDialog(missa: missa),
    );
    if (salvo == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Atualizado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- UI DOS FILTROS ATUALIZADA ---
  Widget _buildFilterBar(ThemeData theme) {
    // Gera lista de anos (ex: do ano passado até +5 anos pra frente)
    final currentYear = DateTime.now().year;
    final anosDisponiveis = List.generate(
      6,
      (index) => (currentYear - 1) + index,
    ); // 2024, 2025...

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 1. Dropdown de ANO
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _filtroAno,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                    items:
                        anosDisponiveis.map((ano) {
                          return DropdownMenuItem(
                            value: ano,
                            child: Text(
                              ano.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _filtroAno = val);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Dropdown de MÊS
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _filtroMes,
                      hint: const Text("Todos"),
                      icon: const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.grey,
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text(
                            "Todos os meses",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        // Gera os 12 meses
                        ...List.generate(12, (index) {
                          // Usa uma data qualquer para formatar o nome do mês
                          final date = DateTime(2024, index + 1);
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              DateFormat(
                                'MMMM',
                                'pt_BR',
                              ).format(date).toUpperCase(),
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _filtroMes = val);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Botão de Ordenação
              InkWell(
                onTap: () => setState(() => _ordemCrescente = !_ordemCrescente),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _ordemCrescente ? Icons.arrow_downward : Icons.arrow_upward,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips de Tipo
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  ['Todos', 'Comum', 'Especial'].map((tipo) {
                    final isSelected = _filtroTipo == tipo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(tipo),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _filtroTipo = tipo),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: theme.colorScheme.primary.withValues(
                          alpha: 0.2,
                        ),
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: "Gestão de Missas",
      showBackButton: false,
      showDrawer: false,
      leading: const HomeAdminButton(),
      actions: [
        IconButton(
          icon: const Icon(Icons.campaign, color: Colors.blue), // Megafone
          tooltip: 'Avisar sobre Agenda do Mês',
          onPressed: _enviarNotificacaoAgenda,
        ),

        AddActionButton(
          tooltip: 'Nova Missa',
          onPressed: () => _showAddMissaOptions(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep, color: Colors.red),
          tooltip: "Limpar tudo",
          onPressed: () => excluirTodasMissas(context),
        ),
      ],
      body: Column(
        children: [
          _buildFilterBar(theme), // Barra de filtros moderna

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("missas")
                      .orderBy("dataHora")
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final missasFiltradas = _aplicarFiltros(docs);

                if (missasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Nenhuma missa encontrada.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  itemCount: missasFiltradas.length,
                  itemBuilder: (context, index) {
                    return _MissaListItem(
                      missaDoc: missasFiltradas[index],
                      onEdit:
                          (doc, isEspecial) =>
                              editarMissaGeneric(context, doc, isEspecial),
                      onDelete: (id, nome) => excluirMissa(context, id, nome),
                      onTap: (id) => context.go('/missa/$id'),
                    );
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

class _MissaListItem extends StatelessWidget {
  final QueryDocumentSnapshot missaDoc;
  final Function(DocumentSnapshot, bool) onEdit;
  final Function(String, String) onDelete;
  final Function(String) onTap;

  const _MissaListItem({
    required this.missaDoc,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = missaDoc.data() as Map<String, dynamic>;

    final dataHora = (data['dataHora'] as Timestamp).toDate();
    final tipo = data["tipo"] ?? "comum";
    final titulo =
        data["titulo"]?.toString().isNotEmpty == true
            ? data["titulo"]
            : "Missa Comum";
    final celebrante = data["celebrante"] ?? "";
    final local = data["local"] ?? "";
    final isEspecial = tipo == "especial";

    // Verifica se expirou (com 1h de tolerância)
    final isExpirada = DateTime.now().isAfter(
      dataHora.add(const Duration(hours: 1)),
    );

    Color statusColor;
    if (isExpirada) {
      statusColor = Colors.grey;
    } else if (isEspecial) {
      statusColor = Colors.amber;
    } else {
      statusColor =
          theme.colorScheme.primary; // Verde ou Azul (Sua cor primária)
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          // Garante que a faixa lateral acompanhe a altura
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Faixa Lateral de Status
              Container(width: 6, color: statusColor),

              // 2. Bloco de Data (Estilo Calendário)
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dataHora.day.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isExpirada ? Colors.grey : Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'pt_BR').format(dataHora).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isExpirada ? Colors.grey : statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(dataHora),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Conteúdo Principal
              Expanded(
                child: InkWell(
                  onTap: () => onTap(missaDoc.id),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tags (Especial / Expirada)
                        Row(
                          children: [
                            if (isExpirada)
                              _StatusTag(text: "REALIZADA", color: Colors.grey),
                            if (isEspecial)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: _StatusTag(
                                  text: "ESPECIAL",
                                  color: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                        if (isExpirada || isEspecial) const SizedBox(height: 6),

                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isExpirada ? Colors.grey : Colors.black87,
                            decoration:
                                isExpirada ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (celebrante.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    celebrante,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (local.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    local,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Menu de Ações
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                onSelected: (value) {
                  if (value == 'edit') onEdit(missaDoc, isEspecial);
                  if (value == 'delete') onDelete(missaDoc.id, titulo);
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Editar"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Excluir"),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String text;
  final MaterialColor color; // Ou Color

  const _StatusTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final Color bgColor = (color).shade50;
    final Color textColor = (color).shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
