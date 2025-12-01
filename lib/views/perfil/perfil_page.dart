import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/utils/helpers/feedbacks_helper.dart';
import '../../notifier/auth_notifier.dart';
import '../../viewmodels/perfil_viewmodel.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late PerfilViewModel _viewModel;

  bool _isEditingName = false;
  final FocusNode _nomeFocusNode = FocusNode();
  bool _isEmailVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = Provider.of<PerfilViewModel>(context);
  }

  void _syncUserData() {
    final authUser = Provider.of<AuthNotifier>(context, listen: false).user;
    if (authUser != null) {
      _viewModel.nomeController.text = authUser.nome;
    }
  }

  @override
  void dispose() {
    _nomeFocusNode.dispose();
    super.dispose();
  }

  void _viewPhotoFullScreen(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            // Fundo escuro
            insetPadding: EdgeInsets.zero,
            child: Stack(
              fit: StackFit.expand, // Ocupa tudo
              children: [
                // Imagem com Zoom
                InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),

                // Botão Fechar (Com SafeArea para não ficar embaixo da barra de status)
                Positioned(
                  top: 10,
                  right: 10,
                  child: SafeArea(
                    child: IconButton(
                      // Fundo semitransparente para garantir que dê para ver o X
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () {
                        // Fecha o diálogo usando o contexto do diálogo
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _removePhoto() async {
    final confirm = await _mostrarDialogoConfirmacao(
      titulo: "Remover Foto",
      mensagem: "Tem certeza que deseja remover sua foto de perfil?",
      icone: Icons.delete_forever,
      textoBotaoConfirmar: "Remover",
      isDestructive: true,
    );

    if (confirm == true) {
      // [CORREÇÃO AQUI] Chama o método do ViewModel
      final sucesso = await _viewModel.removeProfileImage();

      if (sucesso && mounted) {
        FeedbackHelper.showSuccess(context, "Foto removida!");
        // Não precisa de setState aqui, o Provider vai reconstruir a tela
        // quando o AuthNotifier detectar a mudança no Firestore.
      } else if (!sucesso && mounted) {
        FeedbackHelper.showError(
          context,
          _viewModel.errorMessage ?? "Erro ao remover",
        );
      }
    }
  }

  String _getObscuredEmail(String? email) {
    if (email == null) return "Email não informado";
    if (_isEmailVisible) return email;
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final name = parts[0];
      final domain = parts[1];
      if (name.length <= 3) return "$name***@$domain";
      return "${name.substring(0, 3)}***@$domain";
    } catch (e) {
      return email;
    }
  }

  Future<bool?> _mostrarDialogoConfirmacao({
    required String titulo,
    required String mensagem,
    required IconData icone,
    String textoBotaoConfirmar = "Confirmar",
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icone, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mensagem,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                isDestructive
                                    ? Colors.red[700]
                                    : theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            textoBotaoConfirmar,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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

  Future<void> _confirmarRedefinicao(String? email) async {
    if (email == null) return;
    final confirmado = await _mostrarDialogoConfirmacao(
      titulo: "Redefinir Senha",
      mensagem: "Deseja enviar um link de redefinição para:\n$email?",
      icone: Icons.lock_reset,
      textoBotaoConfirmar: "Enviar Link",
    );
    if (confirmado == true) {
      _executarRedefinicao(email);
    }
  }

  Future<void> _executarRedefinicao(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          "Verifique seu e-mail para criar uma nova senha.",
          title: "E-mail Enviado",
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, "Erro ao enviar e-mail: $e");
      }
    }
  }

  Future<void> _confirmarLogout() async {
    final confirmado = await _mostrarDialogoConfirmacao(
      titulo: "Sair da Conta",
      mensagem: "Tem certeza que deseja desconectar do aplicativo?",
      icone: Icons.logout,
      textoBotaoConfirmar: "Sair",
      isDestructive: true,
    );
    if (confirmado == true) {
      _executarLogout();
    }
  }

  Future<void> _executarLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint("Erro ao sair: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _viewModel.user;

    if (_viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FeedbackHelper.showError(context, _viewModel.errorMessage!);
        _viewModel.clearError();
      });
    }

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              onPressed: () => context.pop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 100),
        child: Column(
          children: [
            // --- FOTO E NOME ---
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // [MODIFICADO] GestureDetector para Visualizar Foto
                      GestureDetector(
                        onTap:
                            _viewModel.profileImageUrl != null
                                ? () => _viewPhotoFullScreen(
                                  _viewModel.profileImageUrl!,
                                )
                                : null,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                _viewModel.profileImageUrl != null
                                    ? NetworkImage(_viewModel.profileImageUrl!)
                                    : null,
                            child:
                                _viewModel.profileImageUrl == null
                                    ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    )
                                    : null,
                          ),
                        ),
                      ),

                      if (_viewModel.isLoading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),

                      // Botão Editar (Câmera)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.secondary,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed:
                                _viewModel.isLoading
                                    ? null
                                    : () => _viewModel.handleImageUpload(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // [NOVO] Botão Remover Foto (Só aparece se tiver foto)
                  if (_viewModel.profileImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: _removePhoto,
                        child: Text(
                          "Remover foto",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  // ... (Resto do código do Nome, Email, Grupo Musical e Logout mantido igual)
                  _isEditingName
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _viewModel.nomeController,
                              focusNode: _nomeFocusNode,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              bool success = await _viewModel.updateProfile();
                              if (success) {
                                setState(() => _isEditingName = false);
                                if (mounted) {
                                  FeedbackHelper.showSuccess(
                                    context,
                                    "Nome atualizado!",
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _viewModel.nomeController.text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditingName = true;
                                _nomeFocusNode.requestFocus();
                              });
                            },
                          ),
                        ],
                      ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- INFORMAÇÕES ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    title: const Text("E-mail"),
                    subtitle: Text(_getObscuredEmail(user.email)),
                    trailing: IconButton(
                      icon: Icon(
                        _isEmailVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed:
                          () => setState(
                            () => _isEmailVisible = !_isEmailVisible,
                          ),
                    ),
                  ),
                  const Divider(height: 1, indent: 70, endIndent: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.orange,
                      ),
                    ),
                    title: const Text("Senha"),
                    subtitle: const Text("••••••••"),
                    trailing: TextButton(
                      onPressed: () => _confirmarRedefinicao(user.email),
                      child: const Text("Redefinir"),
                    ),
                  ),

                  if (user.idGrupoMusical != null) ...[
                    const Divider(height: 1, indent: 70, endIndent: 20),
                    _GrupoMusicalInfo(groupId: user.idGrupoMusical!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- AÇÕES ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.logout, color: theme.colorScheme.error),
                    ),
                    title: const Text(
                      "Sair da conta",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: _confirmarLogout,
                  ).animate(delay: 300.ms).fadeIn(),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Versão 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// [NOVO WIDGET] Para carregar o nome do grupo musical
class _GrupoMusicalInfo extends StatelessWidget {
  final String groupId;

  const _GrupoMusicalInfo({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('grupos_musicais')
              .doc(groupId)
              .get(),
      builder: (context, snapshot) {
        String grupoNome = "Carregando...";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          grupoNome = data['nome'] ?? "Grupo Desconhecido";
        } else if (snapshot.hasError) {
          grupoNome = "Erro ao carregar";
        }

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.purple),
          ),
          title: const Text("Grupo Musical"),
          subtitle: Text(
            grupoNome,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
