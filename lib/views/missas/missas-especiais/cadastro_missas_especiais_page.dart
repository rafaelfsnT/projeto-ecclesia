import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/utils/helpers/feedbacks_helper.dart';
import '../../../services/liturgia_service.dart';
import '../../../services/missa_service.dart';
import '../../../widgets/app/app_scaffold.dart';

class CadastroMissaEspecialPage extends StatefulWidget {
  const CadastroMissaEspecialPage({super.key});

  @override
  State<CadastroMissaEspecialPage> createState() =>
      _CadastroMissaEspecialPageState();
}

class _CadastroMissaEspecialPageState extends State<CadastroMissaEspecialPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;
  bool _salvando = false;

  final tituloController = TextEditingController();
  final observacaoController = TextEditingController();
  final outroLocalController = TextEditingController();
  final celebranteController = TextEditingController();
  final comentarioController = TextEditingController();
  final precesController = TextEditingController();
  final missaService = MissaService();

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

  final List<String> _locaisDisponiveis = [
    "Igreja Matriz",
    "Capela N. Sra Sagrado Coração (Casa Branca)",
    "Capela Sagrada Família (Elisa)",
    "Capela Santa Luzia (Elisa)",
    "Capela N. Sra de Fátima (Ponte Alta)",
    "Capela São Vicente de Paulo (Vila Rural 1)",
    "Capela São José (Vila Rural 2)",
    "Capela São N. Sra Aparecida (Jatobá)",
    "Outro",
  ];

  String? _localSelecionado;
  bool _mostrarCampoOutroLocal = false;
  bool _enviarNotificacao = false;

  @override
  void dispose() {
    tituloController.dispose();
    observacaoController.dispose();
    outroLocalController.dispose();
    celebranteController.dispose();
    comentarioController.dispose();
    precesController.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (data != null) setState(() => dataSelecionada = data);
  }

  Future<void> selecionarHora() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final hora = await showTimePicker(
      context: context,
      initialTime: horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) setState(() => horaSelecionada = hora);
  }

  Future<void> salvarMissaEspecial() async {
    if (!_formKey.currentState!.validate() || _salvando) return;

    if (dataSelecionada == null || horaSelecionada == null) {
      FeedbackHelper.showSnackBar(
        context,
        "Selecione a data e a hora da missa.",
        isError: true,
      );
      return;
    }

    String? localFinal;
    if (_localSelecionado == 'Outro') {
      localFinal = outroLocalController.text.trim();
    } else {
      localFinal = _localSelecionado;
    }

    if (localFinal == null || localFinal.isEmpty) {
      FeedbackHelper.showSnackBar(
        context,
        "Por favor, selecione ou digite um local.",
        isError: true,
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final liturgiaDoDia = await LiturgiaService().fetchLiturgia(
        data: dataSelecionada!,
      );

      final Map<String, dynamic> escalaDinamica = {
        'comentarista': null,
        'preces': null,
        'salmo': null,
        'evangelho': null,
        'ministro1': null,
        'ministro2': null,
        'ministro3': null,
        if (liturgiaDoDia.primeiraLeitura.isNotEmpty) 'primeiraLeitura': null,
        if (liturgiaDoDia.segundaLeitura.isNotEmpty) 'segundaLeitura': null,
      };

      await missaService.cadastrarMissaEspecial(
        data: dataSelecionada,
        hora: horaSelecionada,
        titulo: tituloController.text,
        celebrante: celebranteController.text,
        local: localFinal,
        observacao: observacaoController.text,
        tags: _tagsSelecionadas.toList(),
        escala: escalaDinamica,
        comentarioInicial: comentarioController.text,
        precesDaComunidade: precesController.text,
        notificar: _enviarNotificacao,
      );

      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          "Missa Especial cadastrada com sucesso!",
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && context.canPop()) {
            context.pop(); // Volta para a lista
          }
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, "Não foi possível salvar: $e");
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

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
              // Card de Local
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Local da Missa",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _localSelecionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Local da Celebração *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        hint: const Text("Selecione o local"),
                        items:
                            _locaisDisponiveis.map((local) {
                              return DropdownMenuItem(
                                value: local,
                                child: Text(local),
                              );
                            }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            _localSelecionado = valor;
                            _mostrarCampoOutroLocal = valor == 'Outro';
                          });
                        },
                        validator:
                            (v) => v == null ? "Selecione um local" : null,
                      ),

                      if (_mostrarCampoOutroLocal) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: outroLocalController,
                          decoration: const InputDecoration(
                            labelText: "Especifique o local *",
                            hintText: "Ex: Praça Central",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit_location_alt_outlined),
                          ),
                          validator: (value) {
                            if (_mostrarCampoOutroLocal &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Por favor, digite o nome do local.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              // Card Tags
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
              // --- Comentários e Preces
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
                      _buildSectionTitle("Comentários e Preces"),
                      // Marcado como opcional
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: comentarioController,
                        decoration: const InputDecoration(
                          labelText: "Comentário Inicial *",
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
                          labelText: "Preces da Comunidade *",
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
                                    ? "Selecionar Data "
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
                                    ? "Selecionar Hora"
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
              // Card(
              //   elevation: 0,
              //   color: Colors.white,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //     side: BorderSide(color: Colors.grey.shade200),
              //   ),
              //   child: SwitchListTile(
              //     title: const Text(
              //       "Notificar Usuários",
              //       style: TextStyle(fontWeight: FontWeight.w600),
              //     ),
              //     subtitle: const Text(
              //       "Envie um alerta para todos os usuários.",
              //       style: TextStyle(fontSize: 12, color: Colors.grey),
              //     ),
              //     value: _enviarNotificacao,
              //     activeThumbColor: Theme.of(context).primaryColor,
              //     onChanged: (val) => setState(() => _enviarNotificacao = val),
              //   ),
              // ),

              const SizedBox(height: 30),
              // --- Botão Salvar (original) ---
              ElevatedButton(
                onPressed: _salvando ? null : salvarMissaEspecial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child:
                    _salvando
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text(
                          'Cadastrar Missa Especial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
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
