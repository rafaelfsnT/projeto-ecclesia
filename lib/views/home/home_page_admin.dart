import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '/widgets/app/profile_avatar_button.dart';

class HomePageAdmin extends StatelessWidget {
  const HomePageAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: "Ecclesia Admin",
      showBottomNavBar: true,
      actions: const [ProfileAvatarButton()],
      // Gaveta (Drawer) já configurada no AppScaffold, assumindo que você tem um
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho Simples
            Text(
              "Visão Geral",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                "EEEE, d 'de' MMMM",
                'pt_BR',
              ).format(DateTime.now()).capitalize(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // --- 1. AGENDAMENTOS DE HOJE ---
            const _AgendamentosHojeSection(),

            const SizedBox(height: 32),

            // --- 2. PRÓXIMAS MISSAS (NOVO) ---
            const _ProximasMissasSection(),

            // Espaço extra para o scroll não ficar colado no fundo
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _AgendamentosHojeSection extends StatelessWidget {
  const _AgendamentosHojeSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final startOfDay = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day),
    );
    final endOfDay = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Agendamentos Hoje",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/historico-agendamentos'),
              child: const Text("Histórico"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('agendamentos')
                  .where('slotInicio', isGreaterThanOrEqualTo: startOfDay)
                  .where('slotInicio', isLessThanOrEqualTo: endOfDay)
                  .orderBy('slotInicio')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Erro ao carregar agenda."),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LinearProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return _buildEmptyState(context);

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _AppointmentCard(data: data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            "Nenhum agendamento para hoje",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AppointmentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slotInicio = (data['slotInicio'] as Timestamp).toDate();
    final usuarioId = data['usuarioId'] as String;
    final assunto = data['assunto'] as String? ?? "Sem assunto";
    final horarioFormatado = DateFormat('HH:mm').format(slotInicio);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    horarioFormatado,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(usuarioId)
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 80,
                            height: 14,
                            color: Colors.grey[200],
                          );
                        }
                        final nome =
                            snapshot.data?.get('nome') as String? ??
                            "Desconhecido";
                        return Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assunto,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProximasMissasSection extends StatelessWidget {
  const _ProximasMissasSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = Timestamp.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.church,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Próximas Missas",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/listaMissas'),
              child: const Text("Ver Todas"),
            ),
          ],
        ),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('missas')
                  .where('dataHora', isGreaterThanOrEqualTo: now)
                  .orderBy('dataHora')
                  .limit(
                    10,
                  ) // Aumentei para 10, já que agora é horizontal e cabe mais
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Erro ao carregar missas."),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.church_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Nenhuma missa agendada",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            // --- AQUI ESTÁ A MÁGICA DO CARROSSEL ---
            return SizedBox(
              height: 420, // Altura fixa para o carrossel
              child: ListView.builder(
                scrollDirection: Axis.horizontal, // Rola para o lado
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  return Padding(
                    // Adiciona espaço entre os cards
                    padding: const EdgeInsets.only(
                      right: 16.0,
                      bottom: 8.0,
                      top: 2.0,
                    ),
                    child: _MissaCard(data: data, docId: docId),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MissaCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _MissaCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataHora = (data['dataHora'] as Timestamp).toDate();
    final titulo = data['titulo'] as String? ?? "Missa";
    final tipo = data['tipo'] as String? ?? "comum";
    final local = data['local'] as String? ?? "Igreja Matriz";

    final escala = data['escala'] as Map<String, dynamic>? ?? {};
    final totalVagas = escala.length;
    final vagasPreenchidas = escala.values.where((v) => v != null).length;

    final isEspecial = tipo.toLowerCase() == 'especial';
    final percentual = totalVagas == 0 ? 0.0 : vagasPreenchidas / totalVagas;

    Color statusColor =
        percentual == 1.0
            ? Colors.green
            : (percentual >= 0.5 ? Colors.orange : Colors.red);

    final cargosDestaque = [
      {'key': 'comentarista', 'label': 'Comentarista'},
      {'key': 'primeiraLeitura', 'label': '1ª Leitura'},
      {'key': 'salmo', 'label': 'Salmo'},
      {'key': 'segundaLeitura', 'label': '2ª Leitura'},
      {'key': 'ministro1', 'label': 'Ministro 1'},
      {'key': 'ministro2', 'label': 'Ministro 2'},
      {'key': 'ministro3', 'label': 'Ministro 3'},
      {'key': 'ministro4', 'label': 'Ministro 4'},
    ];

    return Container(
      width: 300, // Largura fixa para manter uniformidade no carrossel
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isEspecial
                ? Border.all(color: Colors.amber.shade300, width: 2)
                : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // context.push('/detalheMissa/$docId');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABEÇALHO DO CARD (Fixo) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEspecial ? Colors.amber.shade50 : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat("dd/MM - HH:mm").format(dataHora),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isEspecial)
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    local,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Barra de Progresso Compacta
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentual,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(percentual * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // --- LISTA DE ESCALA (Com Scroll interno caso seja muito grande) ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:
                      cargosDestaque.map((item) {
                        final key = item['key']!;
                        final label = item['label']!;

                        if (escala.containsKey(key)) {
                          final uid = escala[key];
                          return _EscalaRowItem(label: label, uid: uid);
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget Auxiliar para buscar o nome do usuário na escala ---
class _EscalaRowItem extends StatelessWidget {
  final String label;
  final String? uid;

  const _EscalaRowItem({required this.label, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Nome do Cargo (Ex: 1ª Leitura)
          SizedBox(
            width: 90, // Largura fixa para alinhar os nomes
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Nome da Pessoa ou "Vago"
          Expanded(
            child:
                uid == null
                    ? Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.red[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Vago",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                    : FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(uid)
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 60,
                            height: 10,
                            color: Colors.grey[100],
                          );
                        }
                        final nome =
                            snapshot.data?.get('nome') as String? ??
                            "Desconhecido";

                        return Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green[300],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                nome,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
