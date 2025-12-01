import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/aviso_model.dart';

class AvisoService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('avisos');

  Stream<List<Aviso>> streamAvisos() {
    return _col.orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snap) {
      try {
        return snap.docs.map((d) {
          return Aviso.fromDoc(d);
        }).toList();
      } catch (e, st) {
        debugPrint('Erro mapear avisos: $e\n$st');
        return <Aviso>[];
      }
    }).handleError((e) {
      debugPrint('Stream avisos erro (handleError): $e');
    });
  }

  Future<Aviso?> getAvisoById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Aviso.fromDoc(doc);
  }

  Future<void> createAviso(Aviso aviso) async {
    final docRef = _col.doc();
    aviso.id = docRef.id;
    final now = DateTime.now();
    aviso.createdAt ??= now;
    aviso.updatedAt = now;
    await docRef.set(aviso.toMap());
  }

  Future<void> updateAviso(Aviso aviso) async {
    aviso.updatedAt = DateTime.now();
    await _col.doc(aviso.id).update(aviso.toMap());
  }

  Future<void> deleteAviso(String id) async {
    await _col.doc(id).delete();
  }
}
