import 'package:flutter/material.dart';

class GargaloCardWidget extends StatelessWidget {
  final String cargoKey;
  final int gargaloCount;
  final int totalCount;
  final Function(String) formatarCargoCallback;

  const GargaloCardWidget({
    super.key,
    required this.cargoKey,
    required this.gargaloCount,
    required this.totalCount,
    required this.formatarCargoCallback,
  });

  @override
  Widget build(BuildContext context) {
    final taxa = (totalCount == 0) ? 0 : (gargaloCount / totalCount) * 100;

    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
        title: Text(
          formatarCargoCallback(cargoKey),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${taxa.toStringAsFixed(0)}% de ociosidade",
          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          "$gargaloCount de $totalCount vagas",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
      ),
    );
  }
}