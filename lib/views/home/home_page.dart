import '../../widgets/app/notification_drop_down.dart';
import '/widgets/app/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/models/evento_model.dart';
import '/widgets/app/profile_avatar_button.dart';
import '/notifier/auth_notifier.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  Query _buildMissasQuery() {
    return FirebaseFirestore.instance
        .collection("missas")
        .where("dataHora", isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy("dataHora")
        .limit(5);
  }

  int _contarVagasDisponiveis(Map<String, dynamic> escala) {
    if (escala.isEmpty) return 0;
    final cargos = Map<String, dynamic>.from(escala);
    return cargos.values.where((uid) => uid == null).length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final theme = Theme.of(context);

    final String nomeCompleto = auth.user?.nome ?? 'Visitante';
    final String primeiroNome = nomeCompleto.split(' ').first;

    final bool isSomenteLeigo =
        !auth.isAdmin &&
        !auth.canAccessLeitorFeatures &&
        !auth.canAccessMinistroFeatures &&
        !auth.isInMusicalGroup;

    return AppScaffold(
      title: 'Ecclesia',
      showBottomNavBar: true,
      showAppBar: false,
      currentIndex: 0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Olá, $primeiroNome 👋",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          DateFormat(
                            "EEEE, d 'de' MMMM",
                            'pt_BR',
                          ).format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        NotificationDropDown(uid: auth.user?.uid),
                        const SizedBox(width: 10),
                        const ProfileAvatarButton(),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _SectionHeader(
                title: "Próximas Celebrações",
                onTap: () => context.go('/todas-missas'),
              ),

              SizedBox(
                height: 190,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _buildMissasQuery().snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Erro ao carregar."));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final missas = snapshot.data?.docs ?? [];

                    if (missas.isEmpty) {
                      return _buildEmptyStateCard("Nenhuma missa agendada.");
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: missas.length,
                      itemBuilder: (context, index) {
                        return _buildMissaHorizontalCard(
                          context,
                          missas[index],
                          isSomenteLeigo,
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              _SectionHeader(
                title: "Eventos da Paróquia",
                onTap: () => context.go('/all-events'),
              ),

              _buildEventosCarousel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildMissaHorizontalCard(
    BuildContext context,
    DocumentSnapshot missa,
    bool isSomenteLeigo,
  ) {
    final dados = missa.data() as Map<String, dynamic>;
    final dataHora = (dados['dataHora'] as Timestamp).toDate();
    final titulo = dados["titulo"] ?? "Missa Comum";
    final tipo = dados["tipo"] ?? "comum";
    final escala = dados['escala'] as Map<String, dynamic>? ?? {};
    final bool isEspecial = tipo == "especial";
    final int vagas = _contarVagasDisponiveis(escala);

    final theme = Theme.of(context);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEspecial ? Colors.amber.shade300 : Colors.grey.shade200,
          width: isEspecial ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/missa/${missa.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                theme.colorScheme.secondary.withValues(
                                  alpha: 0.15,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  "dd MMM • HH:mm",
                                  'pt_BR',
                                ).format(dataHora).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isEspecial)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Text(
                              "ESPECIAL",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isSomenteLeigo)
                      Row(
                        children: [
                          Icon(
                            vagas > 0
                                ? Icons.people_outline
                                : Icons.check_circle,
                            size: 16,
                            color: vagas > 0 ? Colors.grey[600] : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vagas > 0 ? "$vagas vagas" : "Completa",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  vagas > 0 ? Colors.grey[700] : Colors.green,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
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
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.go('/missa/${missa.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Detalhes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildEventosCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection("eventos")
              .where("dataHora", isGreaterThanOrEqualTo: Timestamp.now())
              .orderBy("dataHora", descending: false)
              .limit(5)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar eventos."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final eventos = snapshot.data?.docs ?? [];

        if (eventos.isEmpty) {
          return _buildEmptyStateCard("Nenhum evento próximo.");
        }

        return SizedBox(
          height: 260,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildEventoCard(context, eventos[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventoCard(BuildContext context, DocumentSnapshot eventoDoc) {
    final dados = eventoDoc.data() as Map<String, dynamic>;
    final String titulo = dados['titulo'] ?? 'Evento';
    final DateTime? dataHora = (dados['dataHora'] as Timestamp?)?.toDate();
    final List<dynamic> imageUrlsList =
        dados['imageUrls'] as List<dynamic>? ?? [];
    final String imageUrl =
        imageUrlsList.isNotEmpty ? imageUrlsList.first.toString() : '';
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        final eventoModel = Evento.fromMap(dados, eventoDoc.id);
        context.push('/eventos/detalhe', extra: eventoModel);
      },
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dataHora != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              "dd MMM • HH:mm",
                              'pt_BR',
                            ).format(dataHora).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    "Ver todos",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
