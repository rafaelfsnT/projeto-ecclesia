import '/services/missa_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '/services/liturgia_service.dart';
import '/widgets/app/app_scaffold.dart';

class CadastroMissaEspecialPage extends StatefulWidget {
  const CadastroMissaEspecialPage({super.key});

  @override
  State<CadastroMissaEspecialPage> createState() =>
      _CadastroMissaEspecialPageState();
}

class _CadastroMissaEspecialPageState extends State<CadastroMissaEspecialPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? dataSelecionada; // Mantém data e hora separados
  TimeOfDay? horaSelecionada; // Mantém data e hora separados
  bool _salvando = false;

  // Seus controllers originais
  final tituloController = TextEditingController();
  final observacaoController = TextEditingController();
  final localController = TextEditingController(text: "Igreja Matriz");
  final celebranteController = TextEditingController();
  final comentarioController = TextEditingController();
  final precesController = TextEditingController();

  // Suas tags originais
  final List<String> _tagsDisponiveis = [
    'Solenidade',
    'Festa',
    'Memória',
    'Missa de Formatura',
    'Missa de Sétimo Dia',
    'Casamento',
    'Crisma',
    'Primeira Comunhão',
  ];
  final Set<String> _tagsSelecionadas = {};

  final missaService = MissaService(); // Seu service

  @override
  void dispose() {
    tituloController.dispose();
    observacaoController.dispose();
    localController.dispose();
    celebranteController.dispose();
    comentarioController.dispose();
    precesController.dispose();
    super.dispose();
  }

  // Suas funções originais de selecionar data/hora
  Future<void> selecionarData() async {
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(const Duration(milliseconds: 100));
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (data != null) setState(() => dataSelecionada = data);
  }

  Future<void> selecionarHora() async {
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(const Duration(milliseconds: 100));
    final hora = await showTimePicker(
      context: context,
      initialTime: horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) setState(() => horaSelecionada = hora);
  }

  // --- Função Salvar CORRIGIDA (sem Future.delayed e usando data/hora separados) ---
  Future<void> salvarMissaEspecial() async {
    if (_salvando || !_formKey.currentState!.validate()) return;

    if (dataSelecionada == null || horaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data e a hora da missa.")),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // Usa apenas a data para buscar a liturgia (como no seu original)
      final liturgiaDoDia = await LiturgiaService().fetchLiturgia(
        data: dataSelecionada!,
      );

      // Cria a escala (como no seu original)
      final Map<String, dynamic> escalaDaMissa = {
        'comentarista': null,
        'preces': null,
        'salmo': null,
        'evangelho': null,
        'ministro1': null,
        'ministro2': null,
        'ministro3': null,
        'musica': null,
        // Adicionado musica aqui também
        if (liturgiaDoDia.primeiraLeitura.isNotEmpty) 'primeiraLeitura': null,
        if (liturgiaDoDia.segundaLeitura.isNotEmpty) 'segundaLeitura': null,
      };

      // Chama o serviço com os parâmetros originais data e hora
      await missaService.cadastrarMissaEspecial(
        data: dataSelecionada,
        // Passa DateTime?
        hora: horaSelecionada,
        // Passa TimeOfDay?
        titulo: tituloController.text.trim(),
        celebrante: celebranteController.text.trim(),
        local: localController.text.trim(),
        observacao: observacaoController.text.trim(),
        tags: _tagsSelecionadas.toList(),
        escala: escalaDaMissa,
        comentarioInicial: comentarioController.text.trim(),
        precesDaComunidade: precesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Missa especial cadastrada com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );

      // Fecha a tela de cadastro e volta para a tela anterior (listaMissas)
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao cadastrar: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // -----------------------------------------------------------------------------

  // Seu widget _buildSectionTitle original
  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // O build permanece EXATAMENTE como você o enviou, sem usar DateTimePickerTile
    return AppScaffold(
      title: "Cadastro de Missa Especial",
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Informações gerais (card) ---
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle("Informações Gerais"),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tituloController,
                        decoration: const InputDecoration(
                          labelText: "Título *",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'O título é obrigatório.'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: localController,
                        decoration: const InputDecoration(
                          labelText: "Local *",
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'O local é obrigatório.'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: celebranteController,
                        decoration: const InputDecoration(
                          labelText: "Celebrante *",
                          border: OutlineInputBorder(),
                        ), // Marcado como opcional
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'O celebrante é obrigatório.'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: observacaoController,
                        decoration: const InputDecoration(
                          labelText: "Observação (Opcional)",
                          border: OutlineInputBorder(),
                        ),
                        // Marcado como opcional
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Tags (card) ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Tags (Opcional)"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children:
                            _tagsDisponiveis.map((tag) {
                              final isSelected = _tagsSelecionadas.contains(
                                tag,
                              );
                              return ChoiceChip(
                                label: Text(tag),
                                selected: isSelected,
                                // Estilo original do ChoiceChip
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Colors.grey.shade400,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected)
                                      _tagsSelecionadas.add(tag);
                                    else
                                      _tagsSelecionadas.remove(tag);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Textos da missa (card) ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle("Textos da Missa (Opcional)"),
                      // Marcado como opcional
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: comentarioController,
                        decoration: const InputDecoration(
                          labelText: "Comentário Inicial",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O comentário inicial é obrigatório.';
                          }
                          return null;
                        },
                        // validator removido
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: precesController,
                        decoration: const InputDecoration(
                          labelText: "Preces da Comunidade",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'As preces são obrigatórias.';
                          }
                          return null;
                        },
                        // validator removido
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Data e Hora (card com botões originais) ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle("Data e Hora"),
                      const SizedBox(height: 12),
                      Row(
                        // Seus botões originais
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: selecionarData,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                dataSelecionada == null
                                    ? "Selecionar Data *"
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(dataSelecionada!),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: selecionarHora,
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                horaSelecionada == null
                                    ? "Selecionar Hora *"
                                    : horaSelecionada!.format(context),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
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
              const SizedBox(height: 24),

              // --- Botão Salvar (original) ---
              ElevatedButton(
                onPressed: _salvando ? null : salvarMissaEspecial,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: AnimatedSwitcher(
                  // Mantém a animação do botão
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder:
                      (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                  child:
                      _salvando
                          ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'Salvar Missa Especial',
                            key: ValueKey('text'),
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
