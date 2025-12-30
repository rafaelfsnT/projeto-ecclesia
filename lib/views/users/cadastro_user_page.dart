import '/services/auth_service.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/app/utils/helpers/feedbacks_helper.dart';
import '/notifier/auth_notifier.dart';

class CadastroUserPage extends StatefulWidget {
  const CadastroUserPage({super.key});

  @override
  State<CadastroUserPage> createState() => _CadastroUserPageState();
}

class _CadastroUserPageState extends State<CadastroUserPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final List<String> _categorias = ['Leitor', 'Coordenador'];
  final Map<String, bool> _categoriasSelecionadas = {};

  bool? _participaDeGrupo;
  List<DocumentSnapshot> _gruposMusicais = [];
  String? _idGrupoSelecionado;
  bool _carregandoGrupos = true;

  String? _idGrupoCoordenado;

  @override
  void initState() {
    super.initState();
    for (var categoria in _categorias) {
      _categoriasSelecionadas[categoria] = false;
    }
    _carregarGruposMusicais();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _carregarGruposMusicais() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('grupos_musicais')
              .where('status', isEqualTo: 'Ativo')
              .get();
      if (mounted) {
        setState(() {
          _gruposMusicais = snapshot.docs;
          _carregandoGrupos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoGrupos = false);
    }
  }

  String _traduzirMensagemErro(String errorRaw) {
    final e = errorRaw.toLowerCase();

    // Erros de E-mail
    if (e.contains('email address is already in use') ||
        e.contains('already exists')) {
      return 'Este e-mail já está cadastrado. Tente fazer login.';
    }
    if (e.contains('badly formatted') || e.contains('invalid email')) {
      return 'O formato do e-mail é inválido.';
    }

    // Erros de Senha
    if (e.contains('password') &&
        (e.contains('weak') || e.contains('6 characters'))) {
      return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
    }
    if (e.contains('network') || e.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    }
    if (e.contains('operation not allowed')) {
      return 'O cadastro está desabilitado temporariamente.';
    }
    return errorRaw.replaceAll("Exception: ", "");
  }

  Future<void> register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    List<String> categoriasFinais =
        _categoriasSelecionadas.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

    if (categoriasFinais.isEmpty) {
      categoriasFinais.add('Leigo');
    } else if (categoriasFinais.contains('Leitor')) {
      if (!categoriasFinais.contains('Leigo')) {
        categoriasFinais.add('Leigo');
      }
    }
    categoriasFinais = categoriasFinais.toSet().toList();

    if (categoriasFinais.contains('Coordenador') &&
        _idGrupoCoordenado == null) {
      FeedbackHelper.showError(
        context,
        'Selecione o grupo que este usuário coordena.',
      );
      return;
    }
    setState(() => isLoading = true);

    final authNotifier = context.read<AuthNotifier>();
    final bool wasAlreadyLoggedIn = authNotifier.isLoggedIn;

    final String? error = await _authService.registerUser(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      categories: categoriasFinais,
      idGrupoMusical: _idGrupoSelecionado,
      idGrupoCoordenado: _idGrupoCoordenado,
      isBeingCreatedByLoggedInUser: wasAlreadyLoggedIn,
    );

    if (mounted) {
      setState(() => isLoading = false);

      if (error == null) {
        if (wasAlreadyLoggedIn) {
          FeedbackHelper.showSuccess(context, 'Membro cadastrado com sucesso!');
          _limparFormulario();
        } else {
          context.go('/verify-email');
        }
      } else {
        final msgEmPortugues = _traduzirMensagemErro(error);
        FeedbackHelper.showError(context, msgEmPortugues);
      }
    }
  }

  void _limparFormulario() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmController.clear();
    setState(() {
      _categoriasSelecionadas.updateAll((key, value) => false);
      _participaDeGrupo = null;
      _idGrupoSelecionado = null;
      _idGrupoCoordenado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authNotifier = context.watch<AuthNotifier>();
    final bool isLoggedIn = authNotifier.isLoggedIn;
    final size = MediaQuery.of(context).size;

    final String pageTitle =
        isLoggedIn ? "Cadastro de Membros" : "Cadastrar-se";
    final String headerTitle = isLoggedIn ? "Novo Membro" : "Crie sua conta";
    final String headerSubtitle =
        isLoggedIn
            ? "Adicione um usuário ao sistema"
            : "Junte-se à nossa comunidade";

    return AppScaffold(
      showAppBar: isLoggedIn,
      showDrawer: isLoggedIn,
      showBackButton: isLoggedIn,
      title: pageTitle,
      body: Container(
        color: Colors.grey[50],
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: isLoggedIn ? 150 : size.height * 0.35,
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
                ),
              ),
            ),

            // --- 2. CONTEÚDO ---
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    SizedBox(height: isLoggedIn ? 10 : size.height * 0.05),

                    // Ícone e Títulos
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isLoggedIn ? Icons.person_add : Icons.how_to_reg,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            headerTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            headerSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- FORMULÁRIO ---
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
                              label: "Email",
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
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Campo obrigatório';
                                if (val.length < 6)
                                  return 'Mínimo 6 caracteres';
                                return null;
                              },
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
                              validator: (val) {
                                if (val != passwordController.text)
                                  return "As senhas não conferem";
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),
                            _buildSectionTitle(theme, "Funções Litúrgicas"),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children:
                                    _categorias.map((categoria) {
                                      return CheckboxListTile(
                                        activeColor: theme.colorScheme.primary,
                                        title: Text(
                                          categoria,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        value:
                                            _categoriasSelecionadas[categoria],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _categoriasSelecionadas[categoria] =
                                                value!;
                                            if (categoria == 'Coordenador' &&
                                                !value) {
                                              _idGrupoCoordenado = null;
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),

                            if (_categoriasSelecionadas['Coordenador'] ==
                                true) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  // Destaque visual
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Qual grupo este usuário coordena?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _carregandoGrupos
                                        ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                        : _gruposMusicais.isEmpty
                                        ? const Text(
                                          "Nenhum grupo encontrado para coordenar.",
                                          style: TextStyle(color: Colors.red),
                                        )
                                        : DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: _idGrupoCoordenado,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 0,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          hint: const Text("Selecione o grupo"),
                                          items:
                                              _gruposMusicais.map((doc) {
                                                final grupo =
                                                    doc.data()
                                                        as Map<String, dynamic>;
                                                return DropdownMenuItem(
                                                  value: doc.id,
                                                  child: Text(
                                                    grupo['nome'] ?? "Sem nome",
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged:
                                              (val) => setState(
                                                () => _idGrupoCoordenado = val,
                                              ),
                                        ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),
                            _buildSectionTitle(theme, "Grupo Musical"),
                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Participa de algum grupo?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioGroup(
                                          onChanged:
                                              (val) => setState(() {
                                                _participaDeGrupo = val;
                                                _idGrupoSelecionado = null;
                                              }),
                                          groupValue: _participaDeGrupo,
                                          child: RadioListTile<bool>(
                                            title: const Text(
                                              'Sim',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            value: true,
                                            activeColor:
                                                theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioGroup(
                                          onChanged:
                                              (val) => setState(() {
                                                _participaDeGrupo = val;
                                                _idGrupoSelecionado = null;
                                              }),
                                          groupValue: _participaDeGrupo,
                                          child: RadioListTile<bool>(
                                            title: const Text(
                                              'Não',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            value: false,
                                            activeColor:
                                                theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_participaDeGrupo == true)
                                    _carregandoGrupos
                                        ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: LinearProgressIndicator(),
                                        )
                                        : DropdownButtonFormField<String>(
                                          initialValue: _idGrupoSelecionado,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            labelText: "Selecione o Grupo",
                                          ),
                                          items:
                                              _gruposMusicais.map((doc) {
                                                final grupo =
                                                    doc.data()
                                                        as Map<String, dynamic>;
                                                return DropdownMenuItem(
                                                  value: doc.id,
                                                  child: Text(
                                                    grupo['nome'] ?? "Sem nome",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged:
                                              (val) => setState(
                                                () => _idGrupoSelecionado = val,
                                              ),
                                          validator:
                                              (val) =>
                                                  (_participaDeGrupo == true &&
                                                          val == null)
                                                      ? 'Selecione o grupo'
                                                      : null,
                                        ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // --- BOTÃO DE AÇÃO COM GRADIENTE ---
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
                                onPressed: isLoading ? null : register,
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
                                        : Text(
                                          isLoggedIn
                                              ? "Cadastrar Usuário"
                                              : "Criar Conta",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 1,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // LINK VOLTAR AO LOGIN
                    if (!isLoggedIn)
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          "Já tem conta? Voltar ao Login",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
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
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      textCapitalization: capitalization,
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
