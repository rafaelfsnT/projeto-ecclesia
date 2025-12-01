import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/utils/helpers/feedbacks_helper.dart';
import '../../notifier/auth_notifier.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      // Opcional: Enviar automaticamente ao abrir a tela
      // sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      timer?.cancel();
      return;
    }

    await user.reload();

    final userAfterReload = FirebaseAuth.instance.currentUser;
    if (userAfterReload == null) {
      timer?.cancel();
      return;
    }

    setState(() {
      isEmailVerified = userAfterReload.emailVerified;
    });

    if (isEmailVerified) {
      timer?.cancel();

      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          "E-mail verificado com sucesso!",
          title: "Bem-vindo!",
        );

        final authNotifier = context.read<AuthNotifier>();
        // Pequeno delay para o usuário ler a mensagem
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go(authNotifier.isAdmin ? '/homeA' : '/home');
        }
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    if (!mounted) return;

    setState(() => canResendEmail = false);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Usuário não está logado.");
      }

      await user.sendEmailVerification();

      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          "Link de verificação enviado! Confira sua caixa de entrada (e spam).",
          title: "E-mail Enviado",
        );
      }

      // Cooldown de 60 segundos
      await Future.delayed(const Duration(seconds: 60));
      if (mounted) {
        setState(() => canResendEmail = true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'too-many-requests') {
        errorMessage = 'Muitas tentativas. Aguarde alguns minutos.';
      } else {
        errorMessage = 'Erro ao enviar: ${e.message}';
      }

      if (mounted) {
        FeedbackHelper.showError(context, errorMessage);
        setState(() => canResendEmail = true);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro inesperado: $e');
        setState(() => canResendEmail = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'seu e-mail';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            // --- 1. HEADER DECORATIVO GRADIENTE ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                          Icons.mark_email_unread_outlined,
                          size: 60,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "Verificação",
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

            // --- 2. CARTÃO FLUTUANTE ---
            Positioned(
              top: size.height * 0.35, // Posicionamento estratégico
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Confirme seu E-mail",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Descrição com o e-mail em destaque
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: "Enviamos um link de confirmação para:\n",
                          ),
                          TextSpan(
                            text: userEmail,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const TextSpan(
                            text:
                                "\n\nPor favor, clique no link para ativar sua conta.",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- BOTÃO GRADIENTE (Enviar E-mail) ---
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient:
                            canResendEmail
                                ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                                : null,
                        // Sem gradiente se desabilitado
                        color: canResendEmail ? null : Colors.grey[300],
                        // Cor sólida se desabilitado
                        boxShadow:
                            canResendEmail
                                ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                                : [],
                      ),
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.send,
                          color:
                              canResendEmail ? Colors.white : Colors.grey[600],
                        ),
                        label: Text(
                          canResendEmail ? "REENVIAR E-MAIL" : "AGUARDE...",
                          style: TextStyle(
                            color:
                                canResendEmail
                                    ? Colors.white
                                    : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        onPressed:
                            canResendEmail ? sendVerificationEmail : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botão Sair (Cancelar)
                    TextButton(
                      onPressed: () {
                        timer?.cancel();
                        FirebaseAuth.instance.signOut();
                        context.go('/login');
                      },
                      child: Text(
                        "Cancelar e Sair",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 50, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}
