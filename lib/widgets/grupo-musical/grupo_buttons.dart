import 'package:flutter/material.dart';

class GrupoButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSalvar;
  final VoidCallback? onCancelar;

  const GrupoButtons({
    super.key,
    required this.isLoading,
    required this.onSalvar,
    this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Expanded(
        //   child: OutlinedButton(
        //     onPressed: isLoading ? null : onCancelar,
        //     child: const Text("Cancelar"),
        //   ),
        // ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSalvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037), // Cor de N. Sra do Carmo
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Cadastrar Grupo", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
