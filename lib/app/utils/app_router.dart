import '/notifier/auth_notifier.dart';
import '/views/agendamentos/agendamentos_secretaria_page.dart';
import '/views/agendamentos/historico_agendamentos_page.dart';
import '/views/ajustes_page.dart';
import '/views/eventos/all_events_page.dart';
import '/views/grupo-musical/cadastro_grupo_musical_page.dart';
import '/views/grupo-musical/lista_grupos_musicais_page.dart';
import '/views/home/meus_compromissos_page.dart';
import '/views/login/login_page.dart';
import '/views/login/forgot_password_page.dart';
import '/views/missas/missas-especiais/cadastro_missas_especiais_page.dart';
import '/views/relatorios/relatorio_agendamentos_page.dart';
import '/views/relatorios/relatorio_cancelamentos_page.dart';
import '/views/relatorios/relatorio_leitores_page.dart';
import '/views/relatorios/relatorio_ministros_page.dart';
import '/views/users/cadastro_user_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/aviso_model.dart';
import '/models/evento_model.dart';
import '/views/avisos/aviso_detail_page.dart';
import '/views/avisos/aviso_form_page.dart';
import '/views/avisos/aviso_list_page.dart';
import '/views/eventos/adicionar_evento_page.dart';
import '/views/eventos/evento_detail_page.dart';
import '/views/home/home_page.dart';
import '/views/home/home_page_admin.dart';
import '/views/missas/cadastro_missa_page.dart';
import '/views/missas/detalhes_missa_page.dart';
import '/views/eventos/eventos_page.dart';
import '/views/missas/lista_missas_page.dart';
import '/views/liturgia/liturgia_view.dart';
import '/views/missas/todas_missas_page.dart';
import '/views/not_found.dart';
import '/views/unauthorized_page.dart';
import '/views/users/cadastro_admin.dart';
import '/views/users/lista_usuarios_page.dart';
import '/views/users/verify_email_page.dart';

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => HomePage()),
      // Rota Home p/ Users Normais
      GoRoute(path: '/homeA', builder: (context, state) => HomePageAdmin()),
      // Rota Home p/ Admins
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      // Rota Login
      GoRoute(
        path: '/forgot',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      // Rota Esqueceu a Senha
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailPage(),
      ),
      // Rota Verificar Email
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),
      // Rota Não Autorizado
      GoRoute(path: '/liturgia', builder: (context, state) => LiturgiaView()),
      // Rota Liturgia

      // Rotas de Missas
      GoRoute(
        path: '/createMissa',
        builder: (context, state) => CadastroMissaPage(),
      ),
      GoRoute(
        path: '/listaMissas',
        builder: (context, state) => ListaMissasPage(),
      ),

      GoRoute(
        path: '/missa/:missaId',
        builder: (context, state) {
          final missaId = state.pathParameters['missaId']!;
          return DetalhesMissaPage(missaId: missaId);
        },
      ),

      GoRoute(
        path: '/todas-missas',
        builder: (context, state) => const TodasMissasPage(),
      ),
      GoRoute(
        path: '/createMissaE',
        builder: (context, state) => const CadastroMissaEspecialPage(),
      ),

      // Rotas de Eventos
      GoRoute(
        path: '/eventos',
        builder: (context, state) => const EventosPage(),
      ),
      // Rota somente para ADM, pois tem campo de edição
      GoRoute(
        path: '/eventos/adicionar',
        builder: (context, state) => const AdicionarEventoPage(),
      ),
      // Rota para mostrar todos os Eventos para Users Comuns
      GoRoute(
        path: '/all-events',
        builder: (context, state) => const TodosEventosPage(),
      ),

      GoRoute(
        path: '/eventos/detalhe',
        builder: (context, state) {
          final evento = state.extra as Evento;
          return EventoDetailPage(evento: evento);
        },
      ),

      // Rota de Avisos
      GoRoute(path: '/avisos', builder: (context, state) => AvisoListPage()),
      GoRoute(
        path: '/avisos/adicionar',
        builder: (context, state) => const AvisoFormPage(),
      ),

      GoRoute(
        path: '/avisos/detalhe',
        builder: (context, state) {
          final aviso = state.extra as Aviso;
          return AvisoDetailPage(aviso: aviso);
        },
      ),

      // Rota de Usuários
      GoRoute(
        path: '/cadastro-usuario',
        builder: (context, state) => const CadastroUserPage(),
      ),
      GoRoute(
        path: '/cadastro-admin',
        builder: (context, state) => const CadastroAdminPage(),
      ),
      GoRoute(
        path: '/listasU',
        builder: (context, state) => const ListaUsuariosPage(),
      ),

      // Rota de Grupo Musicais
      GoRoute(
        path: '/cadastroGM',
        builder: (context, state) => const CadastroGrupoMusicalPage(),
      ),
      GoRoute(
        path: '/grupos-musicais',
        builder: (context, state) => const ListaGruposMusicaisPage(),
      ),
      GoRoute(
        path: '/grupos-musicais/novo',
        builder: (context, state) => const CadastroGrupoMusicalPage(),
      ),

      GoRoute(
        path: '/grupos-musicais/editar/:docId',
        builder: (context, state) {
          final docId = state.pathParameters['docId'];
          final extra = state.extra as Map<String, dynamic>?;
          final grupo = extra?['grupo'];
          return CadastroGrupoMusicalPage(docId: docId, grupo: grupo);
        },
      ),

      // Rota de Escalas
      GoRoute(
        path: '/escalas',
        builder: (context, state) => const MeusCompromissosPage(),
      ),

      // Rota de Agendamentos
      GoRoute(
        path: '/agendamentos',
        builder: (context, state) => const AgendamentoSecretariaPage(),
      ),

      GoRoute(
        path: '/historico-agendamentos',
        builder: (context, state) => const HistoricoAgendamentosPage(),
      ),

      // Rota dos Relatórios
      GoRoute(
        path: '/relatorio-leitores',
        builder: (context, state) => const RelatorioLeitoresPage(),
      ),
      GoRoute(
        path: '/relatorio-ministros',
        builder: (context, state) => const RelatorioMinistrosPage(),
      ),
      GoRoute(
        path: '/relatorio-agendamentos',
        builder: (context, state) => const RelatorioAgendamentosPage(),
      ),
      GoRoute(
        path: '/relatorio-cancelamentos',
        builder: (context, state) => const RelatorioCancelamentosPage(),
      ),
      GoRoute(
        path: '/ajustes',
        builder: (context, state) => const AjustesPage(),
      ),
    ],

    // REDIRECT / PROTEÇÕES (Autorização)
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authNotifier.user != null;
      final bool isAdmin = authNotifier.isAdmin;
      final bool emailVerified = authNotifier.isEmailVerified;
      final String location = state.matchedLocation;

      final bool isUserLoading = authNotifier.user?.nome == 'Carregando...';
      if (loggedIn && isUserLoading) {
        return null;
      }

      // Definindo as rotas públicas
      final bool isPublicRoute =
          location == '/login' ||
          location == '/cadastro-usuario' ||
          location == '/forgot';

      final bool isVerifyingRoute = location == '/verify-email';

      const List<String> normalUserAllowedRoutes = [
        '/home',
        '/liturgia',
        '/listaMissas',
        '/todas-missas',
        '/escalas',
        '/all-events',
        '/eventos/detalhe',
        '/agendamentos',
        '/ajustes'
      ];

      // Verifica se não esta logado e se não é uma rota pública
      if (!loggedIn && !isPublicRoute) {
        return '/login';
      }

      // Valida Está LOGADO e É um ADMIN
      if (loggedIn && isAdmin) {
        if (location == '/login' || location == '/verify-email') {
          return '/homeA';
        }
        return null;
      }

      // Valida se está LOGADO, mas não é ADMIN, nem está com email verificado, e não é uma rota pública
      if (loggedIn && !isAdmin && !emailVerified && !isVerifyingRoute) {
        return '/verify-email';
      }

      if (loggedIn && !isAdmin && emailVerified) {
        if (isPublicRoute || isVerifyingRoute) return '/home';
        final bool isAllowedStaticRoute = normalUserAllowedRoutes.contains(
          location,
        );

        final bool isAllowedDynamicMissa = location.startsWith('/missa/');

        if (!isAllowedStaticRoute && !isAllowedDynamicMissa) {
          return '/unauthorized';
        }
      }
      return null;
    },

    errorBuilder: (context, state) => const NotFound(),
  );
}
