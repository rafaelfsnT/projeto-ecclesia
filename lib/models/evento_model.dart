// lib/models/evento_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Evento {
  String? id;
  final String titulo;
  final String descricao;
  final DateTime dataHora;
  final String local;
  final List<String>? imageUrls;

  Evento({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.dataHora,
    required this.local,
    this.imageUrls,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'titulo': titulo,
      'descricao': descricao,
      'dataHora': Timestamp.fromDate(dataHora),
      'local': local,
    };
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      map['imageUrls'] = imageUrls!;
    }
    return map;
  }

  factory Evento.fromMap(Map<String, dynamic> map, String docId) {
    final dynamic raw = map['dataHora'];
    DateTime parsedDate;
    if (raw is Timestamp) {
      parsedDate = raw.toDate();
    } else if (raw is DateTime) {
      parsedDate = raw;
    } else {
      parsedDate = DateTime.now();
    }

    List<String>? urls;
    if (map['imageUrls'] != null) {
      try {
        urls = List<String>.from(map['imageUrls'] as List);
      } catch (_) {
        urls = null;
      }
    }

    return Evento(
      id: docId,
      titulo: map['titulo'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      dataHora: parsedDate,
      local: map['local'] as String? ?? '',
      imageUrls: urls,
    );
  }
}
