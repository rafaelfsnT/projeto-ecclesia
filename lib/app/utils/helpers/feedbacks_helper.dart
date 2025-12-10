import 'package:flutter/material.dart';
import '../../../widgets/missas/auto_dismiss_dialog.dart';
class FeedbackHelper {
  static void showSuccess(
    BuildContext context,
    String message, {
    String title = "Sucesso!",
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AutoDismissDialogContent(
            title: title,
            content: message,
            isSuccess: true,
          ),
    );
  }

  /// Mostra mensagem de ERRO (Vermelho)
  static void showError(
    BuildContext context,
    String message, {
    String title = "Erro",
  }) {
    final cleanMessage = message.replaceAll("Exception: ", "");

    showDialog(
      context: context,
      builder:
          (context) => AutoDismissDialogContent(
            title: title,
            content: cleanMessage,
            isSuccess: false,
          ),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
