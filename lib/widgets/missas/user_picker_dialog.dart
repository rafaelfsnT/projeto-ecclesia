// lib/views/missas/widgets/user_picker_dialog.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserPickerDialog extends StatefulWidget {
  // [NOVO] Precisamos saber quem é o admin
  final String adminUid;

  const UserPickerDialog({super.key, required this.adminUid});

  @override
  State<UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<UserPickerDialog> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Atribuir a um Usuário"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Buscar usuário por nome",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('usuarios')
                        .orderBy('nome')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // [ATUALIZADO] Filtra os usuários
                  final usuarios =
                      snapshot.data!.docs.where((doc) {
                        // [REGRA 2] Não mostra o próprio admin na lista
                        if (doc.id == widget.adminUid) return false;

                        final data = doc.data() as Map<String, dynamic>;
                        final nome =
                            (data['nome'] as String? ?? '').toLowerCase();
                        return nome.contains(_searchQuery);
                      }).toList();

                  if (usuarios.isEmpty) {
                    return const Center(
                      child: Text("Nenhum usuário encontrado."),
                    );
                  }

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final userDoc = usuarios[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final nome = userData['nome'] ?? 'Sem nome';
                      final email = userData['email'] ?? 'Sem email';

                      return ListTile(
                        title: Text(nome),
                        subtitle: Text(email),
                        onTap: () {
                          Navigator.pop(context, userDoc.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancelar"),
        ),
      ],
    );
  }
}
