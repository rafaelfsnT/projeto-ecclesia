import '/widgets/app/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/liturgia_model.dart';
import '/viewmodels/liturgia_viewmodel.dart';

class LiturgiaView extends StatefulWidget {
  const LiturgiaView({super.key});

  @override
  State<LiturgiaView> createState() => _LiturgiaViewState();
}

// 1. Adiciona o SingleTickerProviderStateMixin para o TabController
class _LiturgiaViewState extends State<LiturgiaView>
    with SingleTickerProviderStateMixin {

  // 2. Declara o TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // 3. Inicializa o TabController
    _tabController = TabController(length: 4, vsync: this);
    // Adiciona um listener para reconstruir a tela ao trocar de aba
    // (Necessário para o padrão de 'if (_tabController.index == ...)'
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiturgiaViewModel>().carregarLiturgia();
    });
  }

  @override
  void dispose() {
    // 4. Faz o dispose do controller
    _tabController.dispose();
    super.dispose();
  }

  // 5. O widget 'leituraCard' não é mais necessário, foi substituído
  //    pelo '_LiturgiaTabContent' no final do arquivo.

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LiturgiaViewModel>();

    // Define o conteúdo principal da tela
    Widget bodyContent;
    if (vm.loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (vm.erro != null) {
      bodyContent = Center(child: Text('Erro: ${vm.erro}'));
    } else if (vm.liturgia == null) {
      bodyContent = const Center(child: Text('Nenhuma liturgia carregada'));
    } else {
      // 6. [MUDANÇA PRINCIPAL]
      // O corpo agora é uma Coluna que contém o Título,
      // a TabBar e o conteúdo da aba selecionada.
      bodyContent = Padding(
        padding: const EdgeInsets.all(16.0), // Padding geral da tela
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Título da Liturgia ---
            Text(
              '${vm.liturgia!.liturgia} (${vm.liturgia!.data})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- A TabBar (barra de abas) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.black54,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: "1ª Leitura"),
                  Tab(text: "Salmo"),
                  Tab(text: "2ª Leitura"),
                  Tab(text: "Evangelho"),
                ],
              ),
            ),

            // --- O Conteúdo da Aba (troca dinâmica) ---
            // Usamos um 'Expanded' para que o conteúdo preencha o resto da tela
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildTabContent(vm),
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Liturgia do Dia',
      showBottomNavBar: true,
      currentIndex: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final dataSelecionada = await showDatePicker(
              context: context,
              initialDate: vm.dataSelecionada ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );

            if (dataSelecionada != null) {
              vm.carregarLiturgia(data: dataSelecionada);
            }
          },
        ),
      ],
      // [MUDANÇA] Removemos o SingleChildScrollView daqui
      // pois o conteúdo da aba já é rolável.
      body: bodyContent,
    );
  }

  /// Helper para construir o conteúdo da aba selecionada
  Widget _buildTabContent(LiturgiaViewModel vm) {
    if (vm.liturgia == null) return const SizedBox.shrink();

    // Key é importante para o AnimatedSwitcher saber que o widget mudou
    switch (_tabController.index) {
      case 0:
        return _LiturgiaTabContent(
          key: const ValueKey('leitura1'),
          titulo: "Primeira Leitura",
          textos: vm.liturgia!.primeiraLeitura,
        );
      case 1:
        return _LiturgiaTabContent(
          key: const ValueKey('salmo'),
          titulo: "Salmo Responsorial",
          textos: vm.liturgia!.salmo,
        );
      case 2:
        return _LiturgiaTabContent(
          key: const ValueKey('leitura2'),
          titulo: "Segunda Leitura",
          textos: vm.liturgia!.segundaLeitura,
        );
      case 3:
      default:
        return _LiturgiaTabContent(
          key: const ValueKey('evangelho'),
          titulo: "Evangelho",
          textos: vm.liturgia!.evangelho,
        );
    }
  }
}

/// [NOVO WIDGET]
/// Widget interno para exibir o conteúdo da aba de liturgia.
/// (Baseado no `LeituraTabContent` que fizemos anteriormente)
class _LiturgiaTabContent extends StatelessWidget {
  final String titulo;
  final List<TextoLiturgico> textos;

  const _LiturgiaTabContent({
    super.key,
    required this.titulo,
    required this.textos,
  });

  @override
  Widget build(BuildContext context) {
    if (textos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text("Leitura não disponível."),
      );
    }

    // Usamos um SingleChildScrollView para o caso de o texto ser longo
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Usamos o .map() para o caso de uma leitura ter vários "pedaços"
        // (embora geralmente seja só um)
        children: textos.map((t) {
          final bool isLeitura = titulo.contains("Leitura");

          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Referência (Ex: "1 Jo 4, 7-10")
                Text(
                  '$titulo (${t.referencia})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Título (Ex: "Deus é amor")
                if (t.titulo != null && t.titulo!.isNotEmpty) ...[
                  Text(
                    t.titulo!,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Refrão (Ex: "R. O Senhor venha a nós!")
                if (t.refrao != null && t.refrao!.isNotEmpty) ...[
                  Text(
                    t.refrao!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Texto principal
                Text(
                  t.texto,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),

                // "Palavra do Senhor" (só para leituras)
                if (isLeitura) ...[
                  const SizedBox(height: 20),
                  const Text(
                    "- Palavra do Senhor.",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "- Graças a Deus.",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}