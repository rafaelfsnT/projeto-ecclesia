import '/widgets/app/custom_app_bar.dart';
import '/widgets/app/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/notifier/auth_notifier.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final bool showBackButton;
  final bool showAppBar;
  final bool showDrawer;
  final Widget? leading;
  final int? currentIndex;
  final bool showBottomNavBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.showAppBar = true,
    this.showDrawer = true,
    this.leading,
    this.currentIndex,
    this.showBottomNavBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authNotifier = context.watch<AuthNotifier>();
    final isAdmin = authNotifier.isAdmin;

    // --- Lógica do Botão Voltar ---
    Widget? finalLeading = leading;
    // Se não tem leading definido E pediu botão de voltar
    if (finalLeading == null && showBackButton) {
      finalLeading = IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: "Voltar",
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Fallback seguro
            if (isAdmin) {
              context.go('/homeA');
            } else {
              context.go('/home');
            }
          }
        },
      );
    }

    return Scaffold(
      // [VISUAL] Cor de fundo cinza claro para destacar os cards brancos do body
      backgroundColor: Colors.grey[50],

      extendBody: true,

      appBar:
          showAppBar
              ? CustomAppBar(
                title: title,
                actions: actions,
                showBackButton: showBackButton,
                leading: finalLeading,
              )
              : null,

      drawer: showDrawer ? const AppDrawer() : null,

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400), // Tempo da animação
        switchInCurve: Curves.easeOut, // Curva de entrada suave
        switchOutCurve: Curves.easeIn, // Curva de saída suave

        // O Builder define qual tipo de animação usar (aqui usamos Fade)
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },

        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex ?? 0),
          child: body,
        ),
      ),

      floatingActionButton: floatingActionButton,

      bottomNavigationBar: showBottomNavBar
          ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex ?? 0,
            onTap: (index) => _handleNavigation(context, index, isAdmin),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,

            // Configuração de cores para o Gradiente
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withValues(alpha: 0.6),

            // Ajuste de fonte para não "pular" tamanho ao selecionar
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),

            // [DICA] Remove o efeito de "splash" exagerado se quiser mais suavidade
            // splashFactory: NoSplash.splashFactory,

            items: isAdmin ? _getAdminItems() : _getUserItems(),
          ),
        ),
      )
          : null,
    );
  }

  void _handleNavigation(BuildContext context, int index, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go('/homeA');
          break;
        case 1:
          context.go('/listaMissas');
          break;
        case 2:
          context.go('/todos-relatórios');
          break;
        case 3:
          context.go('/historico-agendamentos');
          break;
        case 4:
          context.go('/ajustes');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 1:
          context.go('/escalas');
          break;
        case 2:
          context.go('/liturgia');
          break;
        case 3:
          context.go('/agendamentos');
          break;
        case 4:
          context.go('/ajustes');
          break; // Ajuste se necessário
      }
    }
  }

  List<BottomNavigationBarItem> _getAdminItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Painel',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.event_note_outlined),
        activeIcon: Icon(Icons.event_note),
        label: 'Missas',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long),
        activeIcon: Icon(Icons.receipt_long_rounded),
        label: 'Relatórios',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history),
        activeIcon: Icon(Icons.history_rounded),
        label: 'Histórico',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Ajustes',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getUserItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Início',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_ind_outlined),
        activeIcon: Icon(Icons.assignment_ind),
        label: 'Compromissos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_outlined),
        activeIcon: Icon(Icons.menu_book),
        label: 'Liturgia',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.access_time_outlined),
        activeIcon: Icon(Icons.access_time_filled),
        label: 'Agenda',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Ajustes',
      ),
    ];
  }
}
