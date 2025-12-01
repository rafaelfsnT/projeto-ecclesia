import '/views/agendamentos/agendamentos_secretaria_page.dart';
import '/views/missas/detalhes_missa_page.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '/widgets/app/profile_avatar_button.dart';

class _Compromisso {
  final String id;
  final String tipo; // 'missa' ou 'agendamento'
  final DateTime dataHora;
  final String titulo;
  final String subtitulo;
  final Map<String, dynamic> dadosCompletos; // Para navegação

  _Compromisso({
    required this.id,
    required this.tipo,
    required this.dataHora,
    required this.titulo,
    required this.subtitulo,
    required this.dadosCompletos,
  });
}

class MeusCompromissosPage extends StatefulWidget {
  const MeusCompromissosPage({super.key});

  @override
  State<MeusCompromissosPage> createState() => _MeusCompromissosPageState();
}

class _MeusCompromissosPageState extends State<MeusCompromissosPage> {
  final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  /// Helper para "embelezar" o nome da função vinda do Firestore.
  String _formatarCargo(String cargoKey) {
    switch (cargoKey) {
      case 'comentarista':
        return 'Comentarista';
      case 'preces':
        return 'Preces';
      case 'ministro1':
        return 'Ministro 1';
      case 'ministro2':
        return 'Ministro 2';
      case 'ministro3':
        return 'Ministro 3';
      case 'primeiraLeitura':
        return '1ª Leitura';
      case 'segundaLeitura':
        return '2ª Leitura';
      case 'salmo':
        return 'Salmo';
      default:
        // Caso tenhamos uma chave desconhecida, apenas a exibe
        return cargoKey;
    }
  }

  /// Encontra todas as funções que o usuário (uid) tem na escala.
  String _getMinhasFuncoes(Map<String, dynamic> escala, String uid) {
    final funcoes = <String>[];
    escala.forEach((key, value) {
      if (value == uid) {
        funcoes.add(_formatarCargo(key));
      }
    });

    if (funcoes.isEmpty) return "Função não encontrada";
    // Junta todas as funções com vírgula: "Ministro 1, Comentarista"
    return funcoes.join(", ");
  }

  List<_Compromisso> _processarMissas(
    List<QueryDocumentSnapshot> docs,
    String uid,
  ) {
    final List<_Compromisso> listaMissas = [];

    // Filtra no cliente
    final minhasMissas = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final escala = data['escala'] as Map<String, dynamic>? ?? {};
      return escala.values.contains(uid);
    });

    for (var missaDoc in minhasMissas) {
      final data = missaDoc.data() as Map<String, dynamic>;
      final escala = data['escala'] as Map<String, dynamic>? ?? {};
      final dataHora = (data['dataHora'] as Timestamp).toDate();
      final minhasFuncoes = _getMinhasFuncoes(escala, uid);

      listaMissas.add(
        _Compromisso(
          id: missaDoc.id,
          tipo: 'missa',
          dataHora: dataHora,
          titulo: data['titulo'] ?? 'Missa Comum',
          subtitulo: "Função: $minhasFuncoes",
          dadosCompletos: data,
        ),
      );
    }
    return listaMissas;
  }

  /// [NOVO] Processa os documentos de agendamento
  List<_Compromisso> _processarAgendamentos(List<QueryDocumentSnapshot> docs) {
    final List<_Compromisso> listaAgendamentos = [];

    for (var agendamentoDoc in docs) {
      final data = agendamentoDoc.data() as Map<String, dynamic>;
      final dataHora = (data['slotInicio'] as Timestamp).toDate();

      // Calcula a hora fim (adiciona 30 min)
      final dataHoraFim = dataHora.add(const Duration(minutes: 30));
      final horaFimStr = DateFormat('HH:mm').format(dataHoraFim);

      listaAgendamentos.add(
        _Compromisso(
          id: agendamentoDoc.id,
          tipo: 'agendamento',
          dataHora: dataHora,
          titulo: "Agendamento na Secretaria",
          subtitulo:
              "Assunto: ${data['assunto'] ?? 'Não especificado'} (até $horaFimStr)",
          dadosCompletos: data,
        ),
      );
    }
    return listaAgendamentos;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserUid == null) {
      return const AppScaffold(
        title: "Meus Compromissos",
        showBackButton: false,
        body: Center(child: Text("Faça login para ver seus compromissos.")),
      );
    }

    return AppScaffold(
      title: "Meus Compromissos",
      showBackButton: false,
      currentIndex: 1,
      showBottomNavBar: true,
      actions: [const ProfileAvatarButton()],
      // [NOVO] StreamBuilder Aninhado
      body: StreamBuilder<QuerySnapshot>(
        // 1. Stream "Pai" (Agendamentos)
        stream:
            FirebaseFirestore.instance
                .collection('agendamentos')
                .where('usuarioId', isEqualTo: currentUserUid)
                .where('slotInicio', isGreaterThanOrEqualTo: Timestamp.now())
                .orderBy('slotInicio') // Ordena no Firestore
                .snapshots(),
        builder: (context, snapshotAgendamentos) {
          // 2. Stream "Filho" (Missas)
          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('missas')
                    .where('dataHora', isGreaterThanOrEqualTo: Timestamp.now())
                    .orderBy('dataHora') // Ordena no Firestore
                    .snapshots(),
            builder: (context, snapshotMissas) {
              // 3. Gerencia o estado de carregamento
              if (!snapshotAgendamentos.hasData || !snapshotMissas.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // (Você pode adicionar tratamento de erro aqui)

              // 4. Processa as listas SEPARADAMENTE
              //    Elas já vêm ordenadas do Firestore
              final listaAgendamentos = _processarAgendamentos(
                snapshotAgendamentos.data!.docs,
              );
              final listaMissas = _processarMissas(
                snapshotMissas.data!.docs,
                currentUserUid!,
              );

              // 5. [LÓGICA DE CONTAGEM]
              // Calcula o total de itens, incluindo os cabeçalhos
              int itemCount = 0;
              bool temMissas = listaMissas.isNotEmpty;
              bool temAgendamentos = listaAgendamentos.isNotEmpty;

              if (temMissas) {
                itemCount +=
                    listaMissas.length + 1; // +1 para o cabeçalho "Missas"
              }
              if (temAgendamentos) {
                itemCount +=
                    listaAgendamentos.length +
                    1; // +1 para o cabeçalho "Agendamentos"
              }

              // 6. Verifica se tudo está vazio
              if (itemCount == 0) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "Você não possui nenhum compromisso futuro.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }

              // 7. [LÓGICA DO ITEMBUILDER]
              // Constrói a lista com base na contagem e nos índices
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // --- Seção de Missas ---
                  if (temMissas) {
                    // Índice 0 é o cabeçalho
                    if (index == 0) {
                      return _buildSectionHeader(
                        context,
                        "Minhas Escalas de Missa",
                      );
                    }
                    // Índices 1 a N (onde N = listaMissas.length)
                    if (index <= listaMissas.length) {
                      final missa =
                          listaMissas[index - 1]; // -1 por causa do cabeçalho
                      return _buildMissaCard(context, missa);
                    }
                    // Se o índice for maior, ele "cai" para o próximo bloco
                    index -= (listaMissas.length + 1);
                  }

                  // --- Seção de Agendamentos ---
                  // O 'index' aqui já foi ajustado (se havia missas)
                  if (temAgendamentos) {
                    // Índice 0 (deste bloco) é o cabeçalho
                    if (index == 0) {
                      return _buildSectionHeader(context, "Meus Agendamentos");
                    }
                    // Índices 1 a N (deste bloco)
                    if (index <= listaAgendamentos.length) {
                      final agendamento = listaAgendamentos[index - 1];
                      return _buildAgendamentoCard(context, agendamento);
                    }
                  }

                  return null; // Não deve acontecer
                },
              );
            },
          );
        },
      ),
    );
  }

  /// [NOVO] Widget para o título da seção
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Card para Missas (Baseado no seu código original)
  Widget _buildMissaCard(BuildContext context, _Compromisso compromisso) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          Icons.church_rounded, // Ícone de Missa
          color: Theme.of(context).colorScheme.secondary,
          size: 32,
        ),
        title: Text(
          DateFormat(
            "EEEE, dd/MM/yyyy 'às' HH:mm",
            'pt_BR',
          ).format(compromisso.dataHora),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "${compromisso.titulo}\n${compromisso.subtitulo}",
            // Ex: Missa Comum \n Função: 1ª Leitura
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // Navega para a página de detalhes da missa
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesMissaPage(missaId: compromisso.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgendamentoCard(BuildContext context, _Compromisso compromisso) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          Icons.business_center_rounded, // Ícone de Secretaria
          color: Colors.brown.shade400,
          size: 32,
        ),
        title: Text(
          DateFormat(
            "EEEE, dd/MM/yyyy 'às' HH:mm",
            'pt_BR',
          ).format(compromisso.dataHora),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "${compromisso.titulo}\n${compromisso.subtitulo}",
            style: TextStyle(
              color: Colors.brown.shade700,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ),

        // [MUDANÇA] Troca o Ícone de Lixeira por "Ver Detalhes"
        trailing: const Icon(Icons.chevron_right_rounded),

        // [MUDANÇA] Adiciona o onTap para navegar
        onTap: () {
          // Navega para a página de agendamento, passando a data
          // para que ela abra no dia correto.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AgendamentoSecretariaPage(
                    dataInicial: compromisso.dataHora,
                  ),
            ),
          );
        },
      ),
    );
  }
}
