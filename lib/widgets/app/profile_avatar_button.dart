import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../notifier/auth_notifier.dart';
import '../../views/perfil/perfil_page.dart'; // Verifique se o caminho está correto

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = context.watch<AuthNotifier>().user?.profileImageUrl;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          // Navegação direta para a página de perfil
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const PerfilPage()));
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            // Borda branca para destacar
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
            child:
                profileImageUrl == null
                    ? Icon(Icons.person, size: 20, color: Colors.grey.shade600)
                    : null,
          ),
        ),
      ),
    );
  }
}
