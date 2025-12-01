import '/app/utils/helpers/feedbacks_helper.dart';
import '/widgets/missas/justificativa_dialog.dart';
import '/widgets/missas/user_picker_dialog.dart';
import '/notifier/auth_notifier.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '/models/liturgia_model.dart';
import '/viewmodels/liturgia_viewmodel.dart';
import '/widgets/missas/detalhes_missas.dart';

class DetalhesMissaPage extends StatefulWidget {
  final String? missaId;
  final DateTime? dataMissa;

  const DetalhesMissaPage({super.key, this.missaId, this.dataMissa})
    : assert(
        missaId != null || dataMissa != null,
        "Deve fornecer `missaId` ou `dataMissa`",
      );

  @override
  State<DetalhesMissaPage> createState() => _DetalhesMissaPageState();
}

class _DetalhesMissaPageState extends State<DetalhesMissaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<DocumentSnapshot> _missaStream;

  @override
  void initState() {
    super.initState();
    // [MUDANÇA] Aumentei para 6 abas (Início, 1ª Lei, Salmo, 2ª Lei, Evang, Preces)
    _tabController = TabController(length: 6, vsync: this);

    initializeDateFormatting('pt_BR', null);

    if (widget.missaId != null) {
      _missaStream =
          FirebaseFirestore.instance
              .collection('missas')
              .doc(widget.missaId)
              .snapshots();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.dataMissa != null) {
        context.read<LiturgiaViewModel>().carregarLiturgia(
          data: widget.dataMissa!,
        );
      } else if (widget.missaId != null) {
        _carregarDataMissaELiturgia();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDataMissaELiturgia() async {
    if (widget.missaId == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('missas')
              .doc(widget.missaId)
              .get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data != null && data['dataHora'] is Timestamp) {
        final dataMissa = (data['dataHora'] as Timestamp).toDate();
        if (mounted) {
          context.read<LiturgiaViewModel>().carregarLiturgia(data: dataMissa);
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar data da missa: $e");
    }
  }

  Future<void> _safeAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (mounted) FeedbackHelper.showSuccess(context, successMessage);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, e.toString());
    }
  }

  bool _isCargoLeitor(String key) {
    final k = key.toLowerCase();
    return k.contains('leitura') || k == 'preces' || k == 'comentarista';
  }

  bool _isCargoMinistro(String key) => key.toLowerCase().contains('ministro');

  bool _isCargoSalmo(String key) => key.toLowerCase() == 'salmo';

  bool _isBloqueioGrupoLeitura(String key) {
    final k = key.toLowerCase();
    return k.contains('leitura') || k == 'preces' || k == 'salmo';
  }

  bool _isBloqueioGrupoMinistro(String key) =>
      key.toLowerCase().contains('ministro');

  bool _isBloqueioGrupoComentarista(String key) =>
      key.toLowerCase() == 'comentarista';

  Future<void> _reservarCargo(String cargoKey) async {
    final theme = Theme.of(context);

    final confirmar = await showDialog<bool>(
      context: context,

      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),

            backgroundColor: Colors.transparent,

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
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 40),

                  const SizedBox(height: 16),

                  const Text(
                    "Confirmar",

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 20,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Deseja assumir esta função na missa?",

                    style: TextStyle(color: Colors.white70),

                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),

                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),

                          child: const Text("Cancelar"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,

                            foregroundColor: theme.colorScheme.primary,
                          ),

                          child: const Text("Assumir"),
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

    await _safeAction(() async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("Usuário não logado.");

      final auth = context.read<AuthNotifier>();

      final docRef = FirebaseFirestore.instance
          .collection('missas')
          .doc(widget.missaId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception("Missa não encontrada.");

        final data = snapshot.data() as Map<String, dynamic>;

        final escalaAtual = data['escala'] as Map<String, dynamic>? ?? {};

        final dataHoraTimestamp = data['dataHora'] as Timestamp?;

        // [NOVO] VALIDAÇÃO DE DATA NO BACKEND (Transação)

        if (dataHoraTimestamp != null) {
          final dataMissa = dataHoraTimestamp.toDate();

          // Adiciona uma tolerância de 1 hora (opcional, ou 0 para bloqueio exato)

          if (DateTime.now().isAfter(
            dataMissa.add(const Duration(minutes: 30)),
          )) {
            throw Exception(
              "Esta missa já foi realizada ou está em andamento. Escala fechada.",
            );
          }
        }

        if (escalaAtual[cargoKey] != null) {
          throw Exception("Ops! Alguém acabou de assumir esta função.");
        }

        // Validações de Limite

        bool jaAssumiuG1 = false;

        bool jaAssumiuG2 = false;

        bool jaAssumiuG3 = false;

        escalaAtual.forEach((key, uid) {
          if (uid == user.uid) {
            if (_isBloqueioGrupoLeitura(key)) jaAssumiuG1 = true;

            if (_isBloqueioGrupoMinistro(key)) jaAssumiuG2 = true;

            if (_isBloqueioGrupoComentarista(key)) jaAssumiuG3 = true;
          }
        });

        if (_isBloqueioGrupoLeitura(cargoKey) && (jaAssumiuG1 || jaAssumiuG3)) {
          throw Exception("Você já assumiu outra função similar.");
        }

        if (_isBloqueioGrupoMinistro(cargoKey) &&
            (jaAssumiuG2 || jaAssumiuG3)) {
          throw Exception("Você já assumiu outra função de ministro.");
        }

        if (_isBloqueioGrupoComentarista(cargoKey) &&
            (jaAssumiuG3 || jaAssumiuG1 || jaAssumiuG2)) {
          throw Exception("O comentarista não pode assumir outras funções.");
        }

        // Permissões

        bool permitido = false;

        if (auth.isAdmin) {
          permitido = true;
        } else {
          if (_isCargoLeitor(cargoKey) && auth.canAccessLeitorFeatures) {
            permitido = true;
          } else if (_isCargoMinistro(cargoKey) &&
              auth.canAccessMinistroFeatures) {
            permitido = true;
          } else if (_isCargoSalmo(cargoKey) && auth.isInMusicalGroup) {
            permitido = true;
          }
        }

        if (_isBloqueioGrupoComentarista(cargoKey) &&
            !auth.isAdmin &&
            !auth.canAccessLeitorFeatures) {
          permitido = false;
        }

        if (!permitido) {
          throw Exception("Você não tem permissão para esta função.");
        }

        transaction.update(docRef, {'escala.$cargoKey': user.uid});
      });
    }, "Função reservada com sucesso!");
  }

  Future<void> _cancelarCargo(String cargoKey, DateTime dataHoraMissa) async {
    final agora = DateTime.now();

    // Se já passou, não permite cancelar via fluxo normal (apenas Admin ou lógica especial se quiser)

    // Mas geralmente, se já passou, passou.

    if (agora.isAfter(dataHoraMissa)) {
      await _safeAction(
        () => Future.error("Não é possível cancelar escala de missa passada."),

        "",
      );

      return;
    }

    final limite = const Duration(hours: 24);

    final bool isLastMinute = dataHoraMissa.difference(agora) < limite;

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

              child: Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),

                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,

                      theme.colorScheme.secondary.withValues(alpha: 0.8),
                    ],
                  ),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  // [CORREÇÃO VISUAL ANTERIOR]
                  children: [
                    const Icon(
                      Icons.question_mark,

                      color: Colors.white,

                      size: 40,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Sair da Escala",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 20,

                        fontWeight: FontWeight.bold,
                      ),
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
                            ),

                            child: const Text("Não"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,

                              foregroundColor: Colors.red,
                            ),

                            child: const Text("Sim, Sair"),
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

    await _safeAction(
      () => _executarCancelamento(cargoKey, justificativa),

      "Você saiu da escala.",
    );
  }

  Future<void> _executarCancelamento(
    String cargoKey,

    String? justificativa,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) throw Exception("Usuário não logado.");

    final docRef = FirebaseFirestore.instance
        .collection('missas')
        .doc(widget.missaId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(docRef, {'escala.$cargoKey': null});

      if (justificativa != null && justificativa.isNotEmpty) {
        final logRef =
            FirebaseFirestore.instance.collection('logs_cancelamentos').doc();

        transaction.set(logRef, {
          'usuarioId': user.uid,

          'cargo': cargoKey,

          'dataCancelamento': Timestamp.now(),

          'justificativa': justificativa,

          'tipo': 'missa',

          'missaId': widget.missaId,
        });
      }
    });
  }

  Future<void> _atribuirCargo(String cargoKey) async {
    final String? currentAdminUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentAdminUid == null) return;

    final String? selectedUid = await showDialog<String>(
      context: context,

      builder: (dialogContext) => UserPickerDialog(adminUid: currentAdminUid),
    );

    if (selectedUid == null) return;

    await _safeAction(() async {
      final docRef = FirebaseFirestore.instance
          .collection('missas')
          .doc(widget.missaId);

      await docRef.update({'escala.$cargoKey': selectedUid});
    }, "Usuário atribuído com sucesso!");
  }

  @override
  Widget build(BuildContext context) {
    if (widget.missaId != null) {
      return _buildMissaView(context);
    } else {
      return _buildLiturgiaView(context);
    }
  }

  Widget _buildMissaView(BuildContext context) {
    final auth = context.read<AuthNotifier>();
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isSomenteLeigo =
        !auth.isAdmin &&
        !auth.canAccessLeitorFeatures &&
        !auth.canAccessMinistroFeatures &&
        !auth.isInMusicalGroup;

    return AppScaffold(
      title: "Detalhes da Missa",
      showBackButton: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _missaStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text("Missa não encontrada."));

          final dados = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final dataHora =
              (dados['dataHora'] is Timestamp)
                  ? (dados['dataHora'] as Timestamp).toDate()
                  : DateTime.now();
          final escala = dados['escala'] as Map<String, dynamic>? ?? {};

          // [NOVO] Recuperando os textos do banco
          final String comentarioDb = dados['comentarioInicial'] ?? "";
          final String precesDb = dados['precesDaComunidade'] ?? "";

          final bool isMissaPassada = DateTime.now().isAfter(
            dataHora.add(const Duration(minutes: 30)),
          );

          bool jaAssumiuG1 = false;
          bool jaAssumiuG2 = false;
          bool jaAssumiuG3 = false;
          if (currentUserUid != null) {
            escala.forEach((key, uid) {
              if (uid == currentUserUid) {
                if (_isBloqueioGrupoLeitura(key)) jaAssumiuG1 = true;
                if (_isBloqueioGrupoMinistro(key)) jaAssumiuG2 = true;
                if (_isBloqueioGrupoComentarista(key)) jaAssumiuG3 = true;
              }
            });
          }

          bool calcularDesabilitar(String cargoKey) {
            if (isMissaPassada) return true;
            if (_isBloqueioGrupoLeitura(cargoKey))
              return jaAssumiuG1 || jaAssumiuG3;
            if (_isBloqueioGrupoMinistro(cargoKey))
              return jaAssumiuG2 || jaAssumiuG3;
            if (_isBloqueioGrupoComentarista(cargoKey))
              return jaAssumiuG3 || jaAssumiuG1 || jaAssumiuG2;
            return false;
          }

          final Map<String, String> escalasFixas = {
            'ministro1': 'Ministro 1',
            'ministro2': 'Ministro 2',
            'ministro3': 'Ministro 3',
          };

          return SingleChildScrollView(
            key: const PageStorageKey('missa_scroll'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dados['titulo'] ?? 'Missa Comum',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        "EEEE, dd/MM/yyyy 'às' HH:mm",
                        'pt_BR',
                      ).format(dataHora),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (isMissaPassada) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          "ENCERRADA",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (dados['local'] != null)
                  Text(
                    "Local: ${dados['local']}",
                    style: const TextStyle(color: Colors.grey),
                  ),

                const Divider(height: 32),

                if (!isSomenteLeigo) ...[
                  Text(
                    "Ministros da Eucaristia",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...escalasFixas.entries.map((e) {
                    return EscalaFixaTile(
                      titulo: e.value,
                      cargoKey: e.key,
                      escala: escala,
                      desabilitarPorLimite: calcularDesabilitar(e.key),
                      onReservar: () => _reservarCargo(e.key),
                      onCancelar: () => _cancelarCargo(e.key, dataHora),
                      onAtribuir: () => _atribuirCargo(e.key),
                    );
                  }),
                  const Divider(height: 32),
                ],

                Text(
                  "Liturgia e Funções",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Consumer<LiturgiaViewModel>(
                  builder: (context, vm, _) {
                    // Não bloqueamos se a liturgia não carregar, pois Comentário/Preces vêm do Firestore
                    final bool liturgiaDisponivel = vm.liturgia != null;

                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Theme.of(context).colorScheme.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            dividerColor: Colors.transparent,
                            padding: const EdgeInsets.all(4),
                            isScrollable: true,
                            tabs: const [
                              Tab(text: "Comentários"),
                              Tab(text: "1ª Lei"),
                              Tab(text: "Salmo"),
                              Tab(text: "2ª Lei"),
                              Tab(text: "Evang"),
                              Tab(text: "Preces"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            final index = _tabController.index;

                            Widget buildContent(
                              String titulo,
                              List<TextoLiturgico>? textos,
                              String key,
                            ) {
                              // Se a lista for nula ou vazia, cria uma mensagem padrão
                              final listaFinal =
                                  (textos != null && textos.isNotEmpty)
                                      ? textos
                                      : [
                                        TextoLiturgico(
                                          referencia: "",
                                          texto: "Texto não disponível.",
                                        ),
                                      ];

                              return LeituraTabContent(
                                titulo: titulo,
                                textos: listaFinal,
                                cargoKey: key,
                                escala: escala,
                                isSomenteLeigo: isSomenteLeigo,
                                desabilitarPorLimite: calcularDesabilitar(key),
                                onReservar: () => _reservarCargo(key),
                                onCancelar: () => _cancelarCargo(key, dataHora),
                                onAtribuir: () => _atribuirCargo(key),
                              );
                            }

                            switch (index) {
                              case 0: // ABA: Início (Comentarista)
                                // [MUDANÇA] Usa o texto do Firestore
                                return buildContent("Comentário Inicial", [
                                  TextoLiturgico(
                                    referencia: "",
                                    texto:
                                        comentarioDb.isNotEmpty
                                            ? comentarioDb
                                            : "Nenhum comentário cadastrado para esta missa.",
                                  ),
                                ], 'comentarista');

                              case 1: // ABA: 1ª Leitura
                                return buildContent(
                                  "Primeira Leitura",
                                  liturgiaDisponivel
                                      ? vm.liturgia!.primeiraLeitura
                                      : null,
                                  'primeiraLeitura',
                                );

                              case 2: // ABA: Salmo
                                return buildContent(
                                  "Salmo Responsorial",
                                  liturgiaDisponivel
                                      ? vm.liturgia!.salmo
                                      : null,
                                  'salmo',
                                );

                              case 3: // ABA: 2ª Leitura
                                return buildContent(
                                  "Segunda Leitura",
                                  liturgiaDisponivel
                                      ? vm.liturgia!.segundaLeitura
                                      : null,
                                  'segundaLeitura',
                                );

                              case 4: // ABA: Evangelho
                                return LeituraTabContent(
                                  titulo: "Evangelho",
                                  textos:
                                      liturgiaDisponivel
                                          ? vm.liturgia!.evangelho
                                          : [],
                                  cargoKey: 'evangelho',
                                  escala: escala,
                                  isSomenteLeigo: isSomenteLeigo,
                                  desabilitarPorLimite: true,
                                  onReservar: () {},
                                  onCancelar: () {},
                                  onAtribuir: () {},
                                );

                              case 5: // ABA: Preces
                                // [MUDANÇA] Usa o texto do Firestore
                                return buildContent("Preces da Comunidade", [
                                  TextoLiturgico(
                                    referencia: "",
                                    texto:
                                        precesDb.isNotEmpty
                                            ? precesDb
                                            : "Nenhuma prece cadastrada.",
                                  ),
                                ], 'preces');

                              default:
                                return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiturgiaView(BuildContext context) {
    return AppScaffold(
      title: "Liturgia",
      showBackButton: true,
      body: Consumer<LiturgiaViewModel>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.liturgia == null) {
            return const Center(child: Text("Nenhuma liturgia carregada"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  vm.liturgia!.liturgia,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                // ... Repita a lógica de Tabs simplificada aqui se desejar ...
                LeituraTabContent(
                  titulo: "Leituras",
                  textos: vm.liturgia!.primeiraLeitura,
                  cargoKey: '',
                  escala: {},
                  isSomenteLeigo: true,
                  desabilitarPorLimite: true,
                  onReservar: () {},
                  onCancelar: () {},
                  onAtribuir: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
