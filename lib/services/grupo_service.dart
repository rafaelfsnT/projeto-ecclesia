import 'package:cloud_firestore/cloud_firestore.dart';

class GrupoService {
  final CollectionReference _col =
  FirebaseFirestore.instance.collection('grupos_musicais');

  Future<DocumentReference> createGrupo(Map<String, dynamic> data) async {
    final now = Timestamp.fromDate(DateTime.now());
    data['dataCriacao'] = data['dataCriacao'] ?? now;
    data['dataAtualizacao'] = now;
    return await _col.add(data);
  }

  Future<void> updateGrupo(String id, Map<String, dynamic> data) async {
    data['dataAtualizacao'] = Timestamp.fromDate(DateTime.now());
    await _col.doc(id).update(data);
  }

  Future<void> deleteGrupo(String id) async {
    await _col.doc(id).delete();
  }

  Future<DocumentSnapshot> getGrupoById(String id) async {
    return await _col.doc(id).get();
  }

  Stream<QuerySnapshot> streamAllGrupos() {
    return _col.orderBy('dataCriacao', descending: true).snapshots();
  }

  Future<bool> existsByName(String nome) async {
    final q = await _col.where('nome', isEqualTo: nome).limit(1).get();
    return q.docs.isNotEmpty;
  }
}
