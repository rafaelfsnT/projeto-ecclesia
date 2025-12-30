import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/utils/helpers/feedbacks_helper.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      FeedbackHelper.showError(context, 'Por favor, informe o e-mail.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Se houver uma conta com esse e-mail, um link de redefinição foi enviado.',
          title: "Verifique seu E-mail",
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.pop();
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Ocorreu um erro. Tente novamente.';
        if (e.code == 'invalid-email') {
          message = 'O formato do e-mail é inválido.';
        } else if (e.code == 'user-not-found') {
          message = 'E-mail não cadastrado.';
        }
        FeedbackHelper.showError(context, message);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro inesperado: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: [
              // 1. HEADER GRADIENTE
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_reset_outlined,
                            size: 50,
                            color: Colors.white,
                          ),
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Redefinir Senha",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),
                ),
              ),


              // 3. CARTÃO FLUTUANTE
              Positioned(
                top: size.height * 0.38,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Esqueceu sua Senha?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Não se preocupe. Digite seu e-mail abaixo e enviaremos as instruções.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      // Campo de Email
                      _buildModernInput(
                        controller: _emailController,
                        label: "E-mail cadastrado",
                        icon: Icons.email_outlined,
                        theme: theme,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 32),

                      // Botão Enviar
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                              : const Text(
                            "Enviar Link",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // [CORREÇÃO] Botão centralizado
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Voltar ao login',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms, duration: 350.ms),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(begin: 50, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}