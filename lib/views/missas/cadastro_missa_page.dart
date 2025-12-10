import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/utils/helpers/feedbacks_helper.dart';
import '/services/liturgia_service.dart';
import '/services/missa_service.dart';
import '/widgets/app/app_scaffold.dart';

class CadastroMissaPage extends StatefulWidget {
  const CadastroMissaPage({super.key});

  @override
  State<CadastroMissaPage> createState() => _CadastroMissaPageState();
}

class _CadastroMissaPageState extends State<CadastroMissaPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;
  bool _salvando = false;

  final comentarioController = TextEditingController();
  final precesController = TextEditingController();
  final outroLocalController = TextEditingController(); // Para "Outro"
  final missaService = MissaService();
  final List<String> _locaisDisponiveis = [
    "Igreja Matriz",
    "Capela N. Sra Sagrado Coração (Casa Branca)",
    "Capela Sagrada Família (Elisa)",
    "Capela Santa Luzia (Elisa)",
    "Capela N. Sra de Fátima (Ponte Alta)",
    "Capela São Vicente de Paulo (Vila Rural 1)",
    "Capela São José (Vila Rural 2)",
    "Capela São N. Sra Aparecida (Jatobá)",
    "Outro", // Opção especial
  ];
  String? _localSelecionado; // Começa vazio para forçar escolha
  bool _mostrarCampoOutroLocal = false;
  bool _enviarNotificacao = false;

  @override
  void dispose() {
    comentarioController.dispose();
    precesController.dispose();
    outroLocalController.dispose();
    super.dispose();
  }

  // Função de selecionar data
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

  // Função de selecionar hora
  Future<void> selecionarHora() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final hora = await showTimePicker(
      context: context,
      initialTime: horaSelecionada ?? TimeOfDay.now(),
    );
    if (hora != null) setState(() => horaSelecionada = hora);
  }

  // Salvar missa
  Future<void> salvarMissa() async {
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

      await missaService.cadastrarMissa(
        data: dataSelecionada,
        hora: horaSelecionada,
        local: localFinal,
        escala: escalaDinamica,
        comentario: comentarioController.text,
        preces: precesController.text,
        notificar: _enviarNotificacao,
      );

      if (mounted) {
        FeedbackHelper.showSuccess(context, "Missa cadastrada com sucesso!");

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Cadastrar Missa",
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              const SizedBox(height: 20),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Comentários e Preces",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      ),
                      const SizedBox(height: 16),
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
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CARD DE DATA E HORA (Mantido)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Data e Hora",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selecionarData,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                dataSelecionada == null
                                    ? "Data"
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(dataSelecionada!),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selecionarHora,
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                horaSelecionada == null
                                    ? "Hora"
                                    : horaSelecionada!.format(context),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).primaryColor,
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

              const SizedBox(height: 30),

              // Card(
              //   elevation: 0, // Mais sutil
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
              //       "Envie um alerta push para todos os usuários sobre esta missa.",
              //       style: TextStyle(fontSize: 12, color: Colors.grey),
              //     ),
              //     value: _enviarNotificacao,
              //     activeThumbColor: Theme.of(context).primaryColor,
              //     onChanged: (val) => setState(() => _enviarNotificacao = val),
              //   ),
              // ),

              const SizedBox(height: 30),

              // BOTÃO DE SALVAR
              ElevatedButton(
                onPressed: _salvando ? null : salvarMissa,
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
                          'Cadastrar Missa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
