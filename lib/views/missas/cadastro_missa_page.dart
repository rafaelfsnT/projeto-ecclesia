import '/services/missa_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '/services/liturgia_service.dart';
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
  final localController = TextEditingController(text: "Igreja Matriz");
  final missaService = MissaService();

  @override
  void dispose() {
    comentarioController.dispose();
    precesController.dispose();
    localController.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    // Remove foco de qualquer campo e esconde o teclado
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

  Future<void> salvarMissa() async {
    if (!_formKey.currentState!.validate() || _salvando) return;
    if (dataSelecionada == null || horaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione a data e a hora da missa.")),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final liturgiaDoDia =
      await LiturgiaService().fetchLiturgia(data: dataSelecionada!);

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
        local: localController.text,
        escala: escalaDinamica,
        comentario: comentarioController.text,
        preces: precesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Missa cadastrada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
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
              // CARD DE INFORMAÇÕES GERAIS
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Informações Gerais",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: localController,
                        decoration: const InputDecoration(
                          labelText: "Local da Missa *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O local é obrigatório.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CARD DE TEXTOS
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Textos da Missa",
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

              // CARD DE DATA E HORA
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: selecionarData,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                dataSelecionada == null
                                    ? "Selecionar Data"
                                    : DateFormat('dd/MM/yyyy').format(dataSelecionada!),
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
                                padding: const EdgeInsets.symmetric(vertical: 14),
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

              // BOTÃO DE SALVAR
              ElevatedButton(
                onPressed: _salvando ? null : salvarMissa,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _salvando
                      ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                  )
                      : const Text('Salvar Missa', key: ValueKey('text')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
