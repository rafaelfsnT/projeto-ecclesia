import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/connection_service.dart';

class OfflineBlockWidget extends StatelessWidget {
  final Widget child;

  const OfflineBlockWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final connectionService = Provider.of<ConnectionService>(context);
    final theme = Theme.of(context);

    const Color kCorMarrom = Color(0xFF5D4037);
    const Color kCorDourado = Color(0xFFD4AF37);

    return Stack(
      children: [
       child,
        if (!connectionService.hasConnection)
          Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Card(
                    elevation: 10,
                    surfaceTintColor: Colors.white,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: kCorDourado, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kCorDourado.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              size: 42,
                              color: kCorMarrom,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Sem Conexão",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: kCorMarrom,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Não foi possível conectar ao servidor.\nVerifique sua conexão e tente novamente.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kCorMarrom,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                await connectionService.checkNow();
                              },
                              child: const Text(
                                "TENTAR NOVAMENTE",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => SystemNavigator.pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: kCorMarrom,
                            ),
                            child: const Text("Fechar Aplicativo"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}