// lib/widgets/app/custom_app_bar.dart

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading; // <-- 1. PARÂMETRO ADICIONADO

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.leading, // <-- 2. ADICIONADO AO CONSTRUTOR
  });

  @override
  Widget build(BuildContext context) {
    // A AppBarTheme definida em theme_app.dart cuidará dos estilos (cor, etc.)
    return AppBar(
      title: Text(title),
      actions: actions,
      // 3. LÓGICA DE EXIBIÇÃO DO ÍCONE À ESQUERDA
      //    Esta lógica prioriza o 'leading' customizado.
      //    Se não houver 'leading', ela verifica o 'showBackButton'.
      //    Se ambos forem falsos, o Flutter lidará (mostrando o ícone do Drawer).
      leading: leading ?? (showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      )
          : null),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}