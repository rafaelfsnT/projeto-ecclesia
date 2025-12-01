import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/app/utils/helpers/feedbacks_helper.dart';

class CadastroAdminPage extends StatefulWidget {
  const CadastroAdminPage({super.key});

  @override
  State<CadastroAdminPage> createState() => _CadastroAdminPageState();
}

class _CadastroAdminPageState extends State<CadastroAdminPage> {
  final _formKey = GlobalKey<FormState>();

  // [ADICIONADO] Controller do Nome
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> registerAdmin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    firebase_core.FirebaseApp? tempApp;
    try {
      tempApp = await firebase_core.Firebase.initializeApp(
        name: 'adminCreation',
        options: firebase_core.Firebase.app().options,
      );

      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = cred.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
              'nome':
                  nameController.text.trim(), // [CORREÇÃO] Usa o nome digitado
              'email': emailController.text.trim(),
              'role': 'admin',
              'categorias': [],
              'ativo': true,
              'criadoEm': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        // [CORREÇÃO] Usa o Helper com Gradiente
        FeedbackHelper.showSuccess(
          context,
          'Administrador criado com sucesso!',
          title: "Sucesso",
        );

        // Limpa campos
        emailController.clear();
        passwordController.clear();
        confirmController.clear();
        nameController.clear();

        // Pequeno delay para ler a mensagem e voltar
        Future.delayed(const Duration(seconds: 2), () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/listaU');
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Erro de autenticação.");
    } catch (e) {
      _showErrorDialog("Erro inesperado: $e");
    } finally {
      if (tempApp != null) await tempApp.delete();
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Erro"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Novo Administrador',
      showDrawer: true,
      showAppBar: true,
      showBackButton: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Criar Acesso Administrativo",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Este usuário terá controle total do sistema",
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(theme, "Dados Pessoais"),
                      const SizedBox(height: 16),

                      // [ADICIONADO] Campo Nome Completo
                      _buildModernInput(
                        controller: nameController,
                        label: "Nome Completo",
                        icon: Icons.person_outline,
                        theme: theme,
                        capitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16),

                      _buildModernInput(
                        controller: emailController,
                        label: "E-mail",
                        icon: Icons.email_outlined,
                        theme: theme,
                        inputType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      _buildModernInput(
                        controller: passwordController,
                        label: "Senha",
                        icon: Icons.lock_outline,
                        theme: theme,
                        isPassword: true,
                        obscureText: obscurePassword,
                        onToggleVisibility:
                            () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                        validator:
                            (val) =>
                                (val != null && val.length < 6)
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                      ),

                      const SizedBox(height: 16),

                      _buildModernInput(
                        controller: confirmController,
                        label: "Confirmar Senha",
                        icon: Icons.lock_reset,
                        theme: theme,
                        isPassword: true,
                        obscureText: obscureConfirmPassword,
                        onToggleVisibility:
                            () => setState(
                              () =>
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword,
                            ),
                        validator:
                            (val) =>
                                (val != passwordController.text)
                                    ? 'As senhas não conferem'
                                    : null,
                      ),

                      const SizedBox(height: 32),

                      Container(
                        width: double.infinity,
                        height: 54,
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
                          onPressed: isLoading ? null : registerAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Text(
                                    "Cadastrar Admin",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1,
                                    ),
                                  ),
                        ),
                      ),
                    ],
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? inputType,
    TextCapitalization capitalization = TextCapitalization.none, // Padrão none
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      textCapitalization: capitalization,
      // Aplica capitalização se necessário
      validator:
          validator ??
          (val) => (val == null || val.isEmpty) ? 'Campo obrigatório' : null,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleVisibility,
                )
                : null,
      ),
    );
  }
}
