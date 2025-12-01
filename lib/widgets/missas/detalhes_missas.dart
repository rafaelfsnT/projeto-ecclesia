import '/models/liturgia_model.dart';
import '/notifier/auth_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

bool _isCargoLeitor(String key) {
  final lowerKey = key.toLowerCase();
  return lowerKey.contains('leitura') ||
      lowerKey == 'preces' ||
      lowerKey == 'comentarista';
}

bool _isCargoMinistro(String key) => key.toLowerCase().contains('ministro');

bool _isCargoSalmo(String key) => key.toLowerCase() == 'salmo';

/// Card de escala para funções "Fixas" (Comentarista, Ministros, etc.)
class EscalaFixaTile extends StatelessWidget {
  final String titulo;
  final String cargoKey;
  final Map<String, dynamic> escala;
  final bool desabilitarPorLimite;
  final VoidCallback onReservar;
  final VoidCallback onCancelar; // Para usuários E admins
  final VoidCallback onAtribuir;

  const EscalaFixaTile({
    super.key,
    required this.titulo,
    required this.cargoKey,
    required this.escala,
    required this.desabilitarPorLimite, // <-- MUDANÇA
    required this.onReservar,
    required this.onCancelar,
    required this.onAtribuir,
  });

  @override
  Widget build(BuildContext context) {
    final uidOcupante = escala[cargoKey];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final euOcupei = uidOcupante == currentUid;
    final auth = context.read<AuthNotifier>();
    final bool isAdmin = auth.isAdmin;

    bool permitido = isAdmin;
    if (!permitido) {
      if (_isCargoLeitor(cargoKey)) {
        permitido = auth.canAccessLeitorFeatures;
      } else if (_isCargoMinistro(cargoKey)) {
        permitido = auth.canAccessMinistroFeatures;
      }
    }

    String subtituloDisponivel = "Disponível";
    if (!permitido && !isAdmin) subtituloDisponivel = "Permissão necessária";
    if (desabilitarPorLimite && !euOcupei && uidOcupante == null && !isAdmin) {
      subtituloDisponivel = "Limite atingido";
    }
    if (isAdmin && uidOcupante == null) {
      subtituloDisponivel = "Disponível para atribuir";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: _buildTrailingWidget(
          context: context,
          uidOcupante: uidOcupante,
          isAdmin: isAdmin,
          euOcupei: euOcupei,
          permitido: permitido,
          desabilitarPorLimite: desabilitarPorLimite,
          onAtribuir: onAtribuir,
          onReservar: onReservar,
          onCancelar: onCancelar,
        ),
        subtitle:
            uidOcupante != null
                ? FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uidOcupante)
                          .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Text("Carregando...");
                    if (!snap.data!.exists) {
                      return const Text(
                        "Usuário desconhecido",
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    final nome = snap.data!['nome'] ?? "Sem nome";
                    return Text(
                      "Ocupado por: $nome",
                      style: TextStyle(
                        color:
                            euOcupei
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black,
                        fontWeight:
                            euOcupei ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  },
                )
                : Text(
                  subtituloDisponivel,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color:
                        (permitido && !desabilitarPorLimite) || isAdmin
                            ? Colors.green.shade700
                            : Colors.grey,
                  ),
                ),
      ),
    );
  }

  Widget? _buildTrailingWidget({
    required BuildContext context,
    required String? uidOcupante,
    required bool isAdmin,
    required bool euOcupei,
    required bool permitido,
    required bool desabilitarPorLimite,
    required VoidCallback onAtribuir,
    required VoidCallback onReservar,
    required VoidCallback onCancelar,
  }) {
    if (uidOcupante == null) {
      // --- CASO 1: Vaga LIVRE ---
      if (isAdmin) {
        // [CORREÇÃO] ADMIN VÊ APENAS "ATRIBUIR"
        return FilledButton(
          onPressed: onAtribuir,
          child: const Text("Atribuir"),
        );
      } else {
        // USUÁRIO VÊ SÓ "ASSUMIR"
        return FilledButton(
          onPressed: (permitido && !desabilitarPorLimite) ? onReservar : null,
          child: const Text("Assumir"),
        );
      }
    } else {
      // --- CASO 2: Vaga OCUPADA ---
      if (euOcupei) {
        // Ocupada por MIM (seja eu user ou admin)
        return OutlinedButton(
          onPressed: onCancelar,
          child: const Text("Cancelar"),
        );
      } else if (isAdmin) {
        // Ocupada por OUTRO, mas eu sou ADMIN
        return OutlinedButton(
          onPressed: onCancelar,
          child: const Text("Remover"),
        );
      } else {
        // Ocupada por outro, e eu sou USER
        return null;
      }
    }
  }
}

Widget _buildActionButtons({
  required BuildContext context,
  required String? uidOcupante,
  required bool isAdmin,
  required bool euOcupei,
  required bool permitido,
  required bool desabilitarPorLimite,
  required VoidCallback onAtribuir,
  required VoidCallback onReservar,
  required VoidCallback onCancelar,
}) {
  if (uidOcupante == null) {
    // --- CASO 1: Vaga LIVRE ---
    if (isAdmin) {
      // [CORREÇÃO] ADMIN VÊ APENAS "ATRIBUIR"
      return FilledButton(onPressed: onAtribuir, child: const Text("Atribuir"));
    } else {
      // USUÁRIO VÊ SÓ "ASSUMIR"
      return FilledButton(
        onPressed: (permitido && !desabilitarPorLimite) ? onReservar : null,
        child: const Text("Assumir"),
      );
    }
  } else {
    // --- CASO 2: Vaga OCUPADA ---
    if (euOcupei) {
      // Ocupada por MIM
      return OutlinedButton(
        onPressed: onCancelar,
        child: const Text("Cancelar"),
      );
    } else if (isAdmin) {
      // Ocupada por OUTRO, mas eu sou ADMIN
      return OutlinedButton(
        onPressed: onCancelar,
        child: const Text("Remover"),
      );
    } else {
      // Ocupada por outro, e eu sou USER
      return const SizedBox.shrink();
    }
  }
}

class EscalaLeituraReadOnlyTile extends StatelessWidget {
  final String titulo;
  final String cargoKey;
  final Map<String, dynamic> escala;

  const EscalaLeituraReadOnlyTile({
    super.key,
    required this.titulo,
    required this.cargoKey,
    required this.escala,
  });

  @override
  Widget build(BuildContext context) {
    final uidOcupante = escala[cargoKey];

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle:
                uidOcupante != null
                    ? FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(uidOcupante)
                              .get(),
                      builder: (context, snap) {
                        /* ... FutureBuilder igual ... */
                        if (!snap.hasData) return const Text("Carregando...");
                        if (!snap.data!.exists) {
                          return const Text(
                            "Usuário desconhecido",
                            style: TextStyle(color: Colors.red),
                          );
                        }
                        final nome = snap.data!['nome'] ?? "Sem nome";
                        return Text("Responsável: $nome");
                      },
                    )
                    : Text(
                      "Disponível",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green.shade700,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class EscalaActionRow extends StatelessWidget {
  final String cargoKey;
  final Map<String, dynamic> escala;
  final bool desabilitarPorLimite;
  final VoidCallback onReservar;
  final VoidCallback onCancelar;
  final VoidCallback onAtribuir;

  const EscalaActionRow({
    super.key,
    required this.cargoKey,
    required this.escala,
    required this.desabilitarPorLimite, // <-- MUDANÇA
    required this.onReservar,
    required this.onCancelar,
    required this.onAtribuir,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthNotifier>();
    final uidOcupante = escala[cargoKey];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final euOcupei = uidOcupante == currentUid;
    final bool isAdmin = auth.isAdmin;

    bool permitido = isAdmin;
    if (!permitido) {
      if (_isCargoLeitor(cargoKey)) {
        permitido = auth.canAccessLeitorFeatures;
      } else if (_isCargoSalmo(cargoKey)) {
        permitido = auth.isInMusicalGroup;
      }
    }

    String subtituloDisponivel = "Disponível para assumir";
    if (!permitido && !isAdmin) subtituloDisponivel = "Função não permitida";
    if (desabilitarPorLimite && !euOcupei && uidOcupante == null && !isAdmin) {
      subtituloDisponivel = "Limite atingido";
    }
    if (isAdmin && uidOcupante == null) {
      subtituloDisponivel = "Atribuir a um usuário";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Subtítulo
              Expanded(
                child:
                    uidOcupante != null
                        ? FutureBuilder<DocumentSnapshot>(
                          // ... (FutureBuilder igual)
                          future:
                              FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(uidOcupante)
                                  .get(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const Text("Carregando...");
                            }
                            if (!snap.data!.exists) {
                              return const Text(
                                "Usuário desconhecido",
                                style: TextStyle(color: Colors.red),
                              );
                            }
                            final nome = snap.data!['nome'] ?? "Sem nome";
                            return Text(
                              "Ocupado por: $nome",
                              style: TextStyle(
                                color:
                                    euOcupei
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black,
                                fontWeight:
                                    euOcupei
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            );
                          },
                        )
                        : Text(
                          subtituloDisponivel,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color:
                                (permitido && !desabilitarPorLimite)
                                    ? Colors.green.shade700
                                    : Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(width: 16),

              _buildActionButtons(
                context: context,
                uidOcupante: uidOcupante,
                isAdmin: isAdmin,
                euOcupei: euOcupei,
                permitido: permitido,
                desabilitarPorLimite: desabilitarPorLimite,
                onAtribuir: onAtribuir,
                onReservar: onReservar,
                onCancelar: onCancelar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LeituraTabContent extends StatelessWidget {
  final String titulo;
  final List<TextoLiturgico> textos;
  final String cargoKey;
  final Map<String, dynamic> escala;
  final bool isSomenteLeigo;
  final bool desabilitarPorLimite;
  final VoidCallback onReservar;
  final VoidCallback onCancelar;
  final VoidCallback onAtribuir;

  const LeituraTabContent({
    super.key,
    required this.titulo,
    required this.textos,
    required this.cargoKey,
    required this.escala,
    required this.isSomenteLeigo,
    required this.desabilitarPorLimite,
    required this.onReservar,
    required this.onCancelar,
    required this.onAtribuir,
  });

  @override
  Widget build(BuildContext context) {
    if (textos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text("Leitura não disponível."),
      );
    }
    final t = textos.first;
    final bool isLeitura = titulo.contains("Leitura");
    final bool showEscala = (cargoKey != 'evangelho');

    // [CORREÇÃO AQUI] Lógica para mostrar referência apenas se existir
    String tituloExibicao = titulo;
    if (t.referencia.isNotEmpty) {
      tituloExibicao = '$titulo (${t.referencia})';
    }

    return SingleChildScrollView(
      key: ValueKey(cargoKey),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto e Metadados
          Text(
            tituloExibicao, // Usa a string tratada
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (t.titulo != null && t.titulo!.isNotEmpty) ...[
            Text(
              t.titulo!,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (t.refrao != null && t.refrao!.isNotEmpty) ...[
            Text(
              t.refrao!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            t.texto,
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          if (isLeitura) ...[
            const SizedBox(height: 20),
            const Text(
              "- Palavra do Senhor.",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              "- Graças a Deus.",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],

          // Lógica de Escala
          if (showEscala && isSomenteLeigo)
            EscalaLeituraReadOnlyTile(
              titulo: titulo,
              cargoKey: cargoKey,
              escala: escala,
            ),

          if (showEscala && !isSomenteLeigo)
            EscalaActionRow(
              cargoKey: cargoKey,
              escala: escala,
              desabilitarPorLimite: desabilitarPorLimite,
              onReservar: onReservar,
              onCancelar: onCancelar,
              onAtribuir: onAtribuir,
            ),
        ],
      ),
    );
  }
}
