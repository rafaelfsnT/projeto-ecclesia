import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/widgets/admin/admin_list_action_buttons.dart';
import '/app/utils/helpers/feedbacks_helper.dart';
import '/services/admin_service.dart';

class ListaUsuariosPage extends StatefulWidget {
  const ListaUsuariosPage({super.key});

  @override
  State<ListaUsuariosPage> createState() => _ListaUsuariosPageState();
}

class _ListaUsuariosPageState extends State<ListaUsuariosPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchText = _searchController.text);
  }

  void _clearSearch() => _searchController.clear();



  Future<void> _handleAdminAction(
      Future<void> Function() action,
      String successMessage,
      ) async {
    try {
      await action();
      if (mounted) FeedbackHelper.showSuccess(context, successMessage);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, e.toString());
    }
  }

  Future<void> _excluirUsuario(BuildContext context, String uid) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content: const Text("Deseja realmente excluir este usuário?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _handleAdminAction(() async {
        await _adminService.excluirUsuario(uid);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid == uid) await user.delete();
      }, "Usuário excluído com sucesso!");
    }
  }

  Future<void> _desativarUsuario(String uid) async {
    await _handleAdminAction(
          () => _adminService.desativarUsuario(uid),
      "Usuário desativado!",
    );
  }

  Future<void> _ativarUsuario(String uid) async {
    await _handleAdminAction(
          () => _adminService.ativarUsuario(uid),
      "Usuário ativado!",
    );
  }

  Future<void> _resetarSenha(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, "E-mail enviado para $email");
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, "Erro ao enviar e-mail: $e");
      }
    }
  }

  // Lógica inteligente de edição (Diferencia Admin de User)
  Future<void> _showEditUserDialog(
      BuildContext context,
      String uid,
      String nomeAtual,
      List<String> categoriasAtuais,
      String? idGrupoMusicalAtual,
      String role,
      ) async {
    final nameController = TextEditingController(text: nomeAtual);

    // Verifica se é admin para esconder campos desnecessários
    final bool isAdminUser = role == 'admin';

    final List<String> todasCategorias = ['Leigo', 'Leitor', 'Ministro'];
    final Map<String, bool> categoriasSelecionadas = {
      for (var c in todasCategorias) c: categoriasAtuais.contains(c),
    };
    String? idGrupoSelecionado = idGrupoMusicalAtual;

    final Future<QuerySnapshot> gruposMusicaisFuture =
    FirebaseFirestore.instance
        .collection('grupos_musicais')
        .where('status', isEqualTo: 'Ativo')
        .get();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: Text(isAdminUser ? "Editar Admin" : "Editar Usuário"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nome"),
                    ),

                    // Só mostra Categorias e Grupo se NÃO for Admin
                    if (!isAdminUser) ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Categorias:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...todasCategorias.map((categoria) {
                        return CheckboxListTile(
                          title: Text(categoria),
                          value: categoriasSelecionadas[categoria],
                          onChanged: (bool? value) {
                            stfSetState(
                                  () => categoriasSelecionadas[categoria] = value!,
                            );
                          },
                        );
                      }),
                      const Divider(height: 20),
                      const Text(
                        "Grupo Musical:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<QuerySnapshot>(
                        future: gruposMusicaisFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }

                          final grupos = snapshot.data!.docs;
                          List<DropdownMenuItem<String?>> items = [
                            const DropdownMenuItem(
                              value: null,
                              child: Text("Nenhum / Não participa"),
                            ),
                          ];
                          items.addAll(
                            grupos.map((doc) {
                              final grupo = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(grupo['nome'] ?? '...'),
                              );
                            }),
                          );

                          return DropdownButtonFormField<String?>(
                            initialValue: idGrupoSelecionado,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Selecionar grupo",
                            ),
                            isExpanded: true,
                            items: items,
                            onChanged:
                                (val) =>
                                stfSetState(() => idGrupoSelecionado = val),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    final novoNome = nameController.text.trim();
                    final Map<String, dynamic> updateData = {'nome': novoNome};

                    if (!isAdminUser) {
                      final List<String> novasCategorias = [];
                      categoriasSelecionadas.forEach((k, v) {
                        if (v) novasCategorias.add(k);
                      });

                      if (novasCategorias.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Selecione uma categoria."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      updateData['categorias'] = novasCategorias;
                      updateData['idGrupoMusical'] = idGrupoSelecionado;
                    }

                    await _handleAdminAction(
                          () => FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uid)
                          .update(updateData),
                      "Atualizado com sucesso!",
                    );

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddUserOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Cadastrar Usuário Comum'),
                onTap: () {
                  Navigator.pop(bc);
                  context.go('/cadastro-usuario');
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Cadastrar Administrador'),
                onTap: () {
                  Navigator.pop(bc);
                  context.push('/cadastro-admin');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Lista de Usuários",

      // 1. HEADER
      showBackButton: false,
      showDrawer: false,
      leading: const HomeAdminButton(), // Botão Home do admin

      // Botão de Adicionar no Header
      actions: [
        AddActionButton(
          tooltip: 'Adicionar Usuário',
          onPressed: () => _showAddUserOptions(context),
        ),
      ],

      // Botão Flutuante removido (null)
      floatingActionButton: null,

      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar por nome ou e-mail',
                hintText: 'Digite para filtrar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                _searchText.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),


          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection('usuarios').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar usuários"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;
                if (allDocs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum usuário cadastrado."),
                  );
                }

                final searchLower = _searchText.toLowerCase();
                final filteredDocs =
                allDocs.where((doc) {
                  final user = doc.data() as Map<String, dynamic>;
                  final nome = (user['nome'] ?? '').toLowerCase();
                  final email = (user['email'] ?? '').toLowerCase();
                  return nome.contains(searchLower) ||
                      email.contains(searchLower);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum usuário encontrado."),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final user = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;
                    final nome = user['nome'] ?? 'Sem nome';
                    final email = user['email'] ?? '';
                    final role = user['role'] ?? 'user'; // Importante: Pega o cargo
                    final bool isActive = user['ativo'] ?? false;

                    final List<String> categorias = List<String>.from(
                      user['categorias'] ?? [],
                    );
                    final String? idGrupo = user['idGrupoMusical'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: isActive ? null : Colors.grey[200],
                      child: ListTile(
                        leading: Icon(
                          // Ícone Inteligente (Lógica Arq 2)
                          role == 'admin'
                              ? Icons.security // Se for admin
                              : (isActive ? Icons.person : Icons.person_off),
                          color:
                          role == 'admin'
                              ? Colors.blue
                              : (isActive ? Colors.green : Colors.grey),
                        ),
                        title: Text(nome),
                        subtitle: Text(email),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'editar':
                              // Passando o ROLE para o diálogo (Lógica Arq 2)
                                _showEditUserDialog(
                                  context,
                                  uid,
                                  nome,
                                  categorias,
                                  idGrupo,
                                  role,
                                );
                                break;
                              case 'resetar':
                                _resetarSenha(context, email);
                                break;
                              case 'desativar':
                                _desativarUsuario(uid);
                                break;
                              case 'ativar':
                                _ativarUsuario(uid);
                                break;
                              case 'excluir':
                                _excluirUsuario(context, uid);
                                break;
                            }
                          },
                          itemBuilder:
                              (context) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Text("Editar"),
                            ),
                            const PopupMenuItem(
                              value: 'resetar',
                              child: Text("Redefinir Senha"),
                            ),
                            if (isActive)
                              const PopupMenuItem(
                                value: 'desativar',
                                child: Text(
                                  "Desativar",
                                  style: TextStyle(color: Colors.orange),
                                ),
                              )
                            else
                              const PopupMenuItem(
                                value: 'ativar',
                                child: Text(
                                  "Ativar",
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'excluir',
                              child: Text(
                                "Excluir",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}