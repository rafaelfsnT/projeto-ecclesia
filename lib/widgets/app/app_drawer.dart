import '/notifier/auth_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authNotifier = context.watch<AuthNotifier>();

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    // CORREÇÃO: Usando withOpacity(0.8) do JOAO para o efeito
                    theme.colorScheme.secondary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.onPrimary,
                    child: Icon(
                      authNotifier.isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.church,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      authNotifier.isAdmin ? "Menu Administrativo" : "Meu Menu",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CONTEÚDO (LISTVIEW):
            // O ListView do JOAO foi mantido, mas o conteúdo é a junção de ambos.
            Expanded(
              child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // --- ITENS PARA USUÁRIOS NORMAIS (Igual em ambos) ---
                      if (!authNotifier.isAdmin) ...[
                        ListTile(
                          leading: Icon(
                            Icons.local_library,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text("Liturgia"),
                          onTap: () {
                            context.go('/liturgia');
                          },
                        ),
                      ],

                      // --- ITENS EXCLUSIVOS PARA ADMINS (JUNÇÃO DE AMBOS) ---
                      if (authNotifier.isAdmin) ...[
                        ListTile(
                          leading: Icon(
                            Icons.event_available,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text(" Missas "),
                          onTap: () => context.go('/listaMissas'),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.celebration,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text(" Eventos "),
                          onTap: () => context.go('/eventos'),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.announcement,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text(" Avisos "),
                          onTap: () => context.go('/avisos'),
                        ),

                        ListTile(
                          leading: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text(" Usuários "),
                          onTap: () => context.go('/listasU'),
                        ),
                        // Rota corrigida do JOAO
                        ListTile(
                          leading: Icon(
                            Icons.music_note_sharp,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text(" Grupo Musicais "),
                          onTap: () => context.go('/grupos-musicais'),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.receipt_long_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text("Relatórios Leitores"),
                          onTap: () => context.go('/relatorio-leitores'),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.receipt_long,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text("Relatórios Ministros"),
                          onTap: () => context.go('/relatorio-ministros'),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.note_alt_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text("Relatórios Agendamentos"),
                          onTap: () => context.go('/relatorio-agendamentos'),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.cancel_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text("Relatórios Cancelamentos"),
                          onTap: () => context.go('/relatorio-cancelamentos'),
                        ),
                      ],
                    ],
                    // ANIMAÇÃO: Mantida integralmente do JOAO (Estilo)
                  )
                  .animate()
                  .slideX(duration: 250.ms, begin: -0.1, curve: Curves.easeOut)
                  .fadeIn(duration: 250.ms),
            ),

            // PARTE INFERIOR: Mantida do JOAO (que já tinha a animação no final)
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: const Text("Sair"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ).animate(delay: 300.ms).fadeIn(),
            // Animação simples de fade in
          ],
        ),
      ),
    );
  }
}
