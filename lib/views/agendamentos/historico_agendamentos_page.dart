import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoricoAgendamentosPage extends StatefulWidget {
  const HistoricoAgendamentosPage({super.key});

  @override
  State<HistoricoAgendamentosPage> createState() =>
      _HistoricoAgendamentosPageState();
}

class _HistoricoAgendamentosPageState extends State<HistoricoAgendamentosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();
    final theme = Theme.of(context);

    return AppScaffold(
      title: "Histórico de Agendamentos",
      showBackButton: true,
      body: Column(
        children: [
          // 1. O Container da TabBar
          Container(
            color: theme.colorScheme.primary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Próximos", icon: Icon(Icons.event_available)),
                Tab(text: "Realizados", icon: Icon(Icons.history)),
              ],
            ),
          ),

          // 2. O Conteúdo das Abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- ABA 1: FUTUROS ---
                _AgendamentosList(
                  query: FirebaseFirestore.instance
                      .collection('agendamentos')
                      .where('slotInicio', isGreaterThanOrEqualTo: now)
                      .orderBy('slotInicio', descending: false),
                  isHistory: false,
                ),

                // --- ABA 2: PASSADOS (HISTÓRICO) ---
                _AgendamentosList(
                  query: FirebaseFirestore.instance
                      .collection('agendamentos')
                      .where('slotInicio', isLessThan: now)
                      .orderBy('slotInicio', descending: true),
                  isHistory: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DE LISTAGEM GENÉRICO ---
class _AgendamentosList extends StatelessWidget {
  final Query query;
  final bool isHistory;

  const _AgendamentosList({
    required this.query,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                // Text("Erro ao carregar dados: ${snapshot.error}"), // Opcional: mostrar erro técnico
                const Text("Erro ao carregar dados."),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHistory ? Icons.history_toggle_off : Icons.event_busy,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isHistory
                      ? "Nenhum histórico encontrado."
                      : "Nenhum agendamento futuro.",
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _AgendamentoHistoryCard(
              data: data,
              docId: docId,
              isHistory: isHistory,
            );
          },
        );
      },
    );
  }
}

// --- CARD DO ITEM DE AGENDAMENTO ---
class _AgendamentoHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isHistory;

  const _AgendamentoHistoryCard({
    required this.data,
    required this.docId,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotInicio = (data['slotInicio'] as Timestamp).toDate();
    final usuarioId = data['usuarioId'] as String;
    final assunto = data['assunto'] as String? ?? "Sem assunto";

    final diaFormatado = DateFormat("dd/MM/yyyy").format(slotInicio);
    final horaFormatada = DateFormat("HH:mm").format(slotInicio);
    final diaSemana = DateFormat("EEE", "pt_BR").format(slotInicio).toUpperCase();

    final cardColor = Colors.white;
    final stripColor = isHistory ? Colors.grey[400]! : theme.colorScheme.primary;
    final textColor = isHistory ? Colors.grey[600] : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 85,
                color: stripColor.withValues(alpha: 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      horaFormatada,
                      style: TextStyle(
                        color: stripColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diaFormatado.substring(0, 5),
                      style: TextStyle(
                        color: stripColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      diaSemana,
                      style: TextStyle(
                        color: stripColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- CORREÇÃO AQUI ---
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(usuarioId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              width: 100,
                              height: 14,
                              color: Colors.grey[200],
                            );
                          }

                          String nome = "Usuário Desconhecido";

                          // Verifica se tem dados E se o documento existe de fato
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            nome = userData?['nome'] ?? "Sem Nome";
                          } else if (snapshot.hasData && !snapshot.data!.exists) {
                            nome = "Usuário Excluído";
                          }

                          return Text(
                            nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isHistory ? Colors.grey[700] : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      // ---------------------

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.bookmark, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              assunto,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isHistory)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.grey[300],
                      size: 24,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      color: Colors.grey[400],
                      onPressed: () {
                        // Menu de opções
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}