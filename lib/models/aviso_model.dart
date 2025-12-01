import 'package:cloud_firestore/cloud_firestore.dart';

class Aviso {
  String id;
  String title;
  String description;
  DateTime publishedAt;
  DateTime? endsAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  Aviso({
    this.id = '',
    required this.title,
    required this.description,
    DateTime? publishedAt,
    this.endsAt,
    this.createdAt,
    this.updatedAt,
  }) : publishedAt = publishedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'endsAt': endsAt != null ? Timestamp.fromDate(endsAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.fromDate(DateTime.now()),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((k, v) => v == null);
  }

  factory Aviso.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Aviso(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
