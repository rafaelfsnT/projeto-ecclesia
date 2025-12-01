import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/missa_service.dart';

class EditarMissaEspecialDialog extends StatefulWidget {
  final DocumentSnapshot missa;

  const EditarMissaEspecialDialog({super.key, required this.missa});

  @override
  State<EditarMissaEspecialDialog> createState() =>
      EditarMissaEspecialDialogState();
}

class EditarMissaEspecialDialogState extends State<EditarMissaEspecialDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _novaData;
  late TimeOfDay _novaHora;

  late final TextEditingController _tituloController;
  late final TextEditingController _localController;
  late final TextEditingController _celebranteController;
  late final TextEditingController _observacaoController;
  late final TextEditingController _comentarioController;
  late final TextEditingController _precesController;

  // Lista de tags (idealmente, isso viria de um config)
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

  late Set<String> _tagsSelecionadas;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final dados = widget.missa.data() as Map<String, dynamic>;
    final dataHoraAtual = (dados['dataHora'] as Timestamp).toDate();

    _novaData = dataHoraAtual;
    _novaHora = TimeOfDay.fromDateTime(dataHoraAtual);

    _tituloController = TextEditingController(text: dados['titulo'] ?? '');
    _localController = TextEditingController(text: dados['local'] ?? '');
    _celebranteController = TextEditingController(
      text: dados['celebrante'] ?? '',
    );
    _observacaoController = TextEditingController(
      text: dados['observacao'] ?? '',
    );
    _comentarioController = TextEditingController(
      text: dados['comentarioInicial'] ?? '',
    );
    _precesController = TextEditingController(
      text: dados['precesDaComunidade'] ?? '',
    );

    final tagsSalvas = (dados['tags'] as List?)?.cast<String>() ?? [];
    _tagsSelecionadas = tagsSalvas.toSet();

    for (var tag in tagsSalvas) {
      if (!_tagsDisponiveis.contains(tag)) {
        _tagsDisponiveis.add(tag);
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _localController.dispose();
    _celebranteController.dispose();
    _observacaoController.dispose();
    _comentarioController.dispose();
    _precesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final dataDeHoje = DateTime(agora.year, agora.month, agora.day);
    final dataInicial = _novaData.isBefore(dataDeHoje) ? dataDeHoje : _novaData;

    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: dataDeHoje, // Define 'hoje' como a primeira data selecionável
      lastDate: DateTime(2030),
    );
    if (data != null) {
      setState(() => _novaData = data);
    }
  }

  Future<void> _selecionarHora() async {
    final hora = await showTimePicker(context: context, initialTime: _novaHora);
    if (hora != null) {
      setState(() => _novaHora = hora);
    }
  }

  Future<void> _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      await MissaService().editarMissaEspecial(
        missaId: widget.missa.id,
        novaData: _novaData,
        novaHora: _novaHora,
        titulo: _tituloController.text,
        local: _localController.text,
        celebrante: _celebranteController.text,
        observacao: _observacaoController.text,
        comentarioInicial: _comentarioController.text,
        precesDaComunidade: _precesController.text,
        tags: _tagsSelecionadas.toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        // 1. Para o loading
        setState(() => _salvando = false);

        // 2. Mostra um Alerta com a mensagem de erro
        await showDialog(
          context: context, // Usa o context do diálogo de edição
          builder:
              (alertContext) => AlertDialog(
                title: const Text("Erro ao Salvar"),
                // Mostra a mensagem de erro específica vinda do MissaService
                content: Text(e.toString().replaceFirst("Exception: ", "")),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(alertContext),
                    // Fecha só o alerta
                    child: const Text("OK"),
                  ),
                ],
              ),
        );

        // 3. NÃO fecha o diálogo de edição
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar Missa Especial"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: "Título *",
                  border: OutlineInputBorder(),
                ),
                readOnly: _salvando,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                  labelText: "Local *",
                  border: OutlineInputBorder(),
                ),
                readOnly: _salvando,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _celebranteController,
                decoration: const InputDecoration(
                  labelText: "Celebrante *",
                  border: OutlineInputBorder(),
                ),
                readOnly: _salvando,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(
                  labelText: "Observação",
                  border: OutlineInputBorder(),
                ),
                readOnly: _salvando,
              ),
              const Divider(height: 24),

              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  labelText: "Comentário Inicial *",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                readOnly: _salvando,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precesController,
                decoration: const InputDecoration(
                  labelText: "Preces da Comunidade *",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                readOnly: _salvando,
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null,
              ),
              const Divider(height: 24),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd/MM/yyyy').format(_novaData)),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: _salvando ? null : _selecionarData,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_novaHora.format(context)),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: _salvando ? null : _selecionarHora,
              ),
              const SizedBox(height: 16),
              const Text(
                "Tags (Opcional)",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTagsChips(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvarEdicao,
          child:
              _salvando
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Salvar"),
        ),
      ],
    );
  }

  Widget _buildTagsChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children:
          _tagsDisponiveis.map((tag) {
            return ChoiceChip(
              label: Text(tag),
              selected: _tagsSelecionadas.contains(tag),
              onSelected:
                  _salvando
                      ? null
                      : (selecionado) {
                        setState(() {
                          if (selecionado) {
                            _tagsSelecionadas.add(tag);
                          } else {
                            _tagsSelecionadas.remove(tag);
                          }
                        });
                      },
            );
          }).toList(),
    );
  }
}
