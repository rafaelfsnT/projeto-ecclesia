import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/missa_service.dart';

class EditarMissaComumDialog extends StatefulWidget {
  final DocumentSnapshot missa;

  const EditarMissaComumDialog({super.key, required this.missa});

  @override
  State<EditarMissaComumDialog> createState() => EditarMissaComumDialogState();
}

class EditarMissaComumDialogState extends State<EditarMissaComumDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _novaData;
  late TimeOfDay _novaHora;
  late final TextEditingController _comentarioController;
  late final TextEditingController _precesController;
  late final TextEditingController _localController;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final dados = widget.missa.data() as Map<String, dynamic>;
    final dataHoraAtual = (dados['dataHora'] as Timestamp).toDate();

    _novaData = dataHoraAtual;
    _novaHora = TimeOfDay.fromDateTime(dataHoraAtual);
    _comentarioController = TextEditingController(
      text: dados['comentarioInicial'] ?? '',
    );
    _precesController = TextEditingController(
      text: dados['precesDaComunidade'] ?? '',
    );
    _localController = TextEditingController(
      text: dados['local'] ?? 'Igreja Matriz',
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _precesController.dispose();
    _localController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    // 1. Pega a data de hoje e normaliza para meia-noite (ignora a hora)
    final agora = DateTime.now();
    final dataDeHoje = DateTime(agora.year, agora.month, agora.day);

    // 2. Define a data inicial do calendário.
    // Se a data da missa (_novaData) for anterior a hoje,
    // o calendário deve abrir em 'hoje' para evitar um crash.
    final dataInicial = _novaData.isBefore(dataDeHoje) ? dataDeHoje : _novaData;

    // 3. Mostra o DatePicker
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial, // Usa a data inicial calculada
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
      await MissaService().editarMissa(
        missaId: widget.missa.id,
        novaData: _novaData,
        novaHora: _novaHora,
        local: _localController.text,
        // <-- ADICIONAR
        comentario: _comentarioController.text,
        preces: _precesController.text,
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Editar Missa Comum"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                  labelText: "Local *",
                  border: OutlineInputBorder(),
                ),
                readOnly: _salvando,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O local é obrigatório.';
                  }
                  return null;
                },
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  labelText: "Comentário Inicial",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                readOnly: _salvando,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O comentário é obrigatório.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precesController,
                decoration: const InputDecoration(
                  labelText: "Preces da Comunidade",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                readOnly: _salvando,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'As preces são obrigatórias.';
                  }
                  return null;
                },
              ),
              const Divider(height: 24),
              // Agora Data/Hora abaixo das Preces
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
}
