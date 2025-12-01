import 'package:flutter/material.dart';

class JustificativaDialog extends StatefulWidget {
  const JustificativaDialog({super.key});

  @override
  State<JustificativaDialog> createState() => _JustificativaDialogState();
}

class _JustificativaDialogState extends State<JustificativaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  // --- SUAS OPÇÕES ORIGINAIS ---
  final List<String> _opcoes = [
    'Doença / Motivo de Saúde',
    'Emergência Familiar',
    'Conflito de Trabalho / Estudo',
    'Outro',
  ];

  String? _opcaoSelecionada;
  String? _erroOpcao;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- LÓGICA ORIGINAL MANTIDA ---
  void _submit() {
    setState(() {
      _erroOpcao = null;
    });

    if (_opcaoSelecionada == null) {
      setState(() {
        _erroOpcao = "Por favor, selecione um motivo.";
      });
      return;
    }

    if (_opcaoSelecionada == 'Outro') {
      if (_formKey.currentState!.validate()) {
        Navigator.pop(context, _controller.text.trim());
      }
    } else {
      Navigator.pop(context, _opcaoSelecionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // O SEU GRADIENTE
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de Alerta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 16),

              const Text(
                "Cancelar Escala",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              const Text(
                "Atenção: Falta menos de 24 horas para a missa. Por favor, selecione o motivo:",
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // --- LISTA DE OPÇÕES (Container Branco) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: _opcoes.map((motivo) {
                    return RadioListTile<String>(
                      title: Text(
                        motivo,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      value: motivo,
                      groupValue: _opcaoSelecionada,
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onChanged: (value) {
                        setState(() {
                          _opcaoSelecionada = value;
                          _erroOpcao = null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // --- CAMPO 'OUTRO' (Aparece separado se selecionado) ---
              if (_opcaoSelecionada == 'Outro')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _controller,
                      autofocus: true, // Foca automático para facilitar
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: "Especifique o motivo",
                        hintText: "Detalhe o motivo aqui...",
                        filled: true,
                        fillColor: Colors.white, // Fundo branco
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "O motivo é obrigatório.";
                        }
                        if (value.trim().length < 5) {
                          return "Por favor, dê um pouco mais de detalhe.";
                        }
                        return null;
                      },
                    ),
                  ),
                ),

              // --- MENSAGEM DE ERRO (Visualmente destacada) ---
              if (_erroOpcao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _erroOpcao!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // --- BOTÕES ---
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Voltar", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                          "Confirmar",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}