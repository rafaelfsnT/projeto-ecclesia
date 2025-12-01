import '/notifier/auth_notifier.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TodasMissasPage extends StatefulWidget {
  const TodasMissasPage({super.key});

  @override
  State<TodasMissasPage> createState() => _TodasMissasPageState();
}

class _TodasMissasPageState extends State<TodasMissasPage> {
  DateTime? _dataInicial;
  DateTime? _dataFinal;
  String _tipoFiltro = 'todos';

  // [CORREÇÃO 1] O filtro de 'tipo' foi REMOVIDO da query
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection("missas");

    // 1. Filtro de Data Inicial (padrão: hoje)
    if (_dataInicial != null) {
      query = query.where(
        "dataHora",
        isGreaterThanOrEqualTo: Timestamp.fromDate(_dataInicial!),
      );
    } else {
      query = query.where("dataHora", isGreaterThanOrEqualTo: Timestamp.now());
    }

    // 2. Filtro de Data Final
    if (_dataFinal != null) {
      final fimDoDia = DateTime(
        _dataFinal!.year,
        _dataFinal!.month,
        _dataFinal!.day,
        23,
        59,
        59,
      );
      query = query.where(
        "dataHora",
        isLessThanOrEqualTo: Timestamp.fromDate(fimDoDia),
      );
    }

    // [REMOVIDO] O filtro 'query.where("tipo", ...)' foi removido daqui
    // para evitar a restrição de índice composto do Firestore.

    // Sempre ordena pela data (isso funciona)
    query = query.orderBy("dataHora");
    return query;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthNotifier>();
    final bool isSomenteLeigo = !auth.isAdmin &&
        !auth.canAccessLeitorFeatures &&
        !auth.canAccessMinistroFeatures &&
        !auth.isInMusicalGroup;

    return AppScaffold(
      title: "Todas as Missas",
      showBackButton: true,
      showBottomNavBar: true,
      currentIndex: 0,
      body: Column(
        children: [
          // --- SEÇÃO DE FILTROS ---
          Container(
            padding: const EdgeInsets.all(12.0),
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                // Filtros de Data
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerButton(context, isInitial: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDatePickerButton(context, isInitial: false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filtro de Tipo de Missa
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'todos',
                      label: Text('Todas'),
                      icon: Icon(Icons.clear_all),
                    ),
                    ButtonSegment(
                      value: 'comum',
                      label: Text('Comuns'),
                      icon: Icon(Icons.calendar_month),
                    ),
                    ButtonSegment(
                      value: 'especial',
                      label: Text('Especiais'),
                      icon: Icon(Icons.star),
                    ),
                  ],
                  selected: {_tipoFiltro},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _tipoFiltro = newSelection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- LISTA DE MISSAS ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(), // A query agora só filtra data
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Ocorreu um erro ao carregar as missas."),
                  );
                }

                final todasMissas = snapshot.data?.docs ?? [];

                // --- [CORREÇÃO 2] ---
                // Aplicamos o filtro de 'tipo' aqui, no lado do app
                // Isso é rápido e não precisa de índice no Firebase
                final missasFiltradas = todasMissas.where((doc) {
                  if (_tipoFiltro == 'todos') {
                    return true; // Mostra todos
                  }

                  final dados = doc.data() as Map<String, dynamic>? ?? {};
                  // Pega o 'tipo' do documento, se for nulo, assume 'comum'
                  final tipoDaMissa = dados['tipo'] ?? 'comum';

                  return tipoDaMissa == _tipoFiltro; // Compara com o filtro
                }).toList();
                // --- [FIM DA CORREÇÃO] ---


                if (missasFiltradas.isEmpty) { // [MODIFICADO]
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "Nenhuma missa encontrada para os filtros selecionados.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: missasFiltradas.length, // [MODIFICADO]
                  itemBuilder: (context, index) {
                    final missa = missasFiltradas[index]; // [MODIFICADO]
                    return _buildMissaListItem(
                      context,
                      missa,
                      isSomenteLeigo,
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

  // --- WIDGETS AUXILIARES DESTA PÁGINA ---

  // Card de Missa (Estilo "Bonito" de Lista)
  Widget _buildMissaListItem(
      BuildContext context,
      DocumentSnapshot missa,
      bool isSomenteLeigo,
      ) {
    final dados = missa.data() as Map<String, dynamic>;
    final dataHora = (dados['dataHora'] as Timestamp).toDate();
    final titulo = dados["titulo"] ?? "Missa Comum";
    final tipo = dados["tipo"] ?? "comum";
    final escala = dados['escala'] as Map<String, dynamic>? ?? {};
    final int vagas = _contarVagasDisponiveis(escala);
    final List<String> tags =
        (dados['tags'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

    final dia = DateFormat('dd').format(dataHora);
    final mes = DateFormat('MMM', 'pt_BR').format(dataHora).toUpperCase();
    final horaFormatada = DateFormat('HH:mm').format(dataHora);
    final diaDaSemana = DateFormat('EEEE', 'pt_BR').format(dataHora);

    final bool isEspecial = tipo == "especial";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: isEspecial
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dia,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Text(
                mes,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "$diaDaSemana às $horaFormatada",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            // Mostra Vagas (se não for leigo) ou Tags (se for especial)
            if (!isSomenteLeigo)
              _buildVagasInfo(vagas, isSomenteLeigo)
            else if (isEspecial && tags.isNotEmpty)
              _buildTagsList(tags),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 28),
        onTap: () => context.go('/missa/${missa.id}'),
      ),
    );
  }

  // Helper para o DatePicker (copiado da Home)
  Widget _buildDatePickerButton(
      BuildContext context, {
        required bool isInitial,
      }) {
    final text = isInitial
        ? (_dataInicial == null
        ? 'Data Inicial'
        : DateFormat('dd/MM/yyyy').format(_dataInicial!))
        : (_dataFinal == null
        ? 'Data Final'
        : DateFormat('dd/MM/yyyy').format(_dataFinal!));

    return OutlinedButton.icon(
      onPressed: () async {
        final data = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (data != null) {
          setState(() {
            if (isInitial) {
              _dataInicial = data;
            } else {
              _dataFinal = data;
            }
          });
        }
      },
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(text),
    );
  }

  // Helper para Vagas (copiado da Home)
  int _contarVagasDisponiveis(Map<String, dynamic> escala) {
    if (escala.isEmpty) return 0;
    final cargos = Map<String, dynamic>.from(escala);
    cargos.remove('evangelho');
    return cargos.values.where((uid) => uid == null).length;
  }

  // Helper para Vagas UI (copiado da Home)
  Widget _buildVagasInfo(int vagas, bool isSomenteLeigo) {
    if (isSomenteLeigo) {
      return const SizedBox.shrink();
    }
    if (vagas == 0) {
      return const Text("Escala completa", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 14));
    }
    return Text(
      "$vagas vagas disponíveis",
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  // Helper para Tags (copiado da Home)
  Widget _buildTagsList(List<String> tags) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 4.0,
      runSpacing: 0.0,
      children: tags.map((tag) {
        return Chip(
          label: Text(tag),
          labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}