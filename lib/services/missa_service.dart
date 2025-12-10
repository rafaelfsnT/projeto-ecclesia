import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class MissaService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'missas',
  );

  final int duracaoMinutos = 60;
  final int duracaoMinutosEspecial = 90;
  final int maxMissasPorDia = 3;

  Future<int> countMissasPorDia(DateTime data) async {
    final inicioDoDia = DateTime(data.year, data.month, data.day, 0, 0);
    final fimDoDia = DateTime(data.year, data.month, data.day, 23, 59, 59);

    final missasDoDia =
        await _collection
            .where(
              "dataHora",
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDoDia),
            )
            .where(
              "dataHora",
              isLessThanOrEqualTo: Timestamp.fromDate(fimDoDia),
            )
            .get();

    return missasDoDia.docs.length;
  }

  Future<void> deleteAllMissas() async {
    final snapshot = await _collection.get();
    if (snapshot.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> cadastrarMissa({
    required DateTime? data,
    required TimeOfDay? hora,
    required String local,
    required Map<String, dynamic> escala,
    required String comentario,
    required String preces,
    required bool notificar, // [NOVO PARAMETRO]
  }) async {
    if (data == null) throw Exception("A data é obrigatória.");
    if (hora == null) throw Exception("O horário é obrigatório.");
    if (local.trim().isEmpty) throw Exception("O local é obrigatório.");

    final dataHora = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    await _validarConflitos(dataHora: dataHora, duracao: duracaoMinutos);
    await _validarLimiteDiario(dataHora);

    final docData = {
      "dataHora": Timestamp.fromDate(dataHora),
      "local": local.trim(),
      "tipo": "comum",
      "titulo": "Missa Comum", // Garante um título padrão
      "escala": escala,
      "comentarioInicial": comentario.trim(),
      "precesDaComunidade": preces.trim(),
      "criadoEm": FieldValue.serverTimestamp(),
      "notificar": notificar, // [NOVO CAMPO SALVO]
    };

    try {
      await _collection.add(docData);
    } catch (e) {
      throw Exception("Ocorreu um erro ao salvar a missa: $e");
    }
  }

  Future<void> cadastrarMissaEspecial({
    required DateTime? data,
    required TimeOfDay? hora,
    required String titulo,
    required String celebrante,
    required String local,
    String? observacao,
    List<String>? tags,
    required Map<String, dynamic> escala,
    required String comentarioInicial,
    required String precesDaComunidade,
    required bool notificar, // [NOVO PARAMETRO]
  }) async {
    if (data == null) throw Exception("A data é obrigatória.");
    if (hora == null) throw Exception("O horário é obrigatório.");
    if (titulo.trim().isEmpty) throw Exception("O título é obrigatório.");
    if (celebrante.trim().isEmpty)
      throw Exception("O celebrante é obrigatório.");
    if (local.trim().isEmpty) throw Exception("O local é obrigatório.");
    if (comentarioInicial.trim().isEmpty)
      throw Exception("O comentário inicial é obrigatório.");
    if (precesDaComunidade.trim().isEmpty)
      throw Exception("As preces da comunidade são obrigatórias.");

    final dataHora = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    await _validarConflitos(
      dataHora: dataHora,
      duracao: duracaoMinutosEspecial,
    );
    await _validarLimiteDiario(dataHora);

    final cleanTags =
        (tags ?? []).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final docData = {
      "dataHora": Timestamp.fromDate(dataHora),
      "titulo": titulo.trim(),
      "celebrante": celebrante.trim(),
      "local": local.trim(),
      if (observacao != null && observacao.trim().isNotEmpty)
        "observacao": observacao.trim(),
      "tags": cleanTags,
      "tipo": "especial",
      "escala": escala,
      "comentarioInicial": comentarioInicial.trim(),
      "precesDaComunidade": precesDaComunidade.trim(),
      "criadoEm": FieldValue.serverTimestamp(),
      "notificar": notificar,
    };

    try {
      await _collection.add(docData);
    } catch (e) {
      throw Exception("Ocorreu um erro ao salvar a missa especial: $e");
    }
  }

  Future<void> editarMissaByDateTime({
    required String missaId,
    required DateTime novaDataHora,
    String? local,
    String? comentario,
    String? preces,
  }) async {
    if (novaDataHora.isBefore(DateTime.now())) {
      throw Exception("Não é permitido editar para datas/horários passados.");
    }

    await _validarConflitos(
      dataHora: novaDataHora,
      missaIdAtual: missaId,
      duracao: duracaoMinutos,
    );
    await _validarLimiteDiario(novaDataHora, missaIdAtual: missaId);

    final updateData = {
      "dataHora": Timestamp.fromDate(novaDataHora),
      "tipo": "comum",
      "atualizadoEm": FieldValue.serverTimestamp(),
    };

    if (local != null) updateData["local"] = local.trim();
    if (comentario != null) updateData["comentarioInicial"] = comentario.trim();
    if (preces != null) updateData["precesDaComunidade"] = preces.trim();

    await _collection.doc(missaId).update(updateData);
  }

  Future<void> editarMissa({
    required String missaId,
    required DateTime novaData,
    required TimeOfDay novaHora,
    required String local,
    required String comentario,
    required String preces,
  }) async {
    final novaDataHora = DateTime(
      novaData.year,
      novaData.month,
      novaData.day,
      novaHora.hour,
      novaHora.minute,
    );

    if (local.trim().isEmpty) throw Exception("O local é obrigatório.");

    await _validarConflitos(
      dataHora: novaDataHora,
      missaIdAtual: missaId,
      duracao: duracaoMinutos,
    );
    await _validarLimiteDiario(novaDataHora, missaIdAtual: missaId);

    await _collection.doc(missaId).update({
      "dataHora": Timestamp.fromDate(novaDataHora),
      "local": local.trim(),
      "comentarioInicial": comentario.trim(),
      "precesDaComunidade": preces.trim(),
      "atualizadoEm": FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarMissaEspecial({
    required String missaId,
    required DateTime novaData,
    required TimeOfDay novaHora,
    required String titulo,
    required String celebrante,
    required String local,
    String? observacao,
    List<String>? tags,
    required String comentarioInicial,
    required String precesDaComunidade,
  }) async {
    if (titulo.trim().isEmpty) throw Exception("O título é obrigatório.");
    if (celebrante.trim().isEmpty)
      throw Exception("O celebrante é obrigatório.");
    if (local.trim().isEmpty) throw Exception("O local é obrigatório.");
    if (comentarioInicial.trim().isEmpty)
      throw Exception("O comentário inicial é obrigatório.");
    if (precesDaComunidade.trim().isEmpty)
      throw Exception("As preces da comunidade são obrigatórias.");

    final novaDataHora = DateTime(
      novaData.year,
      novaData.month,
      novaData.day,
      novaHora.hour,
      novaHora.minute,
    );

    await _validarConflitos(
      dataHora: novaDataHora,
      missaIdAtual: missaId,
      duracao: duracaoMinutosEspecial,
    );
    await _validarLimiteDiario(novaDataHora, missaIdAtual: missaId);

    final cleanTags =
        (tags ?? []).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final docData = {
      "dataHora": Timestamp.fromDate(novaDataHora),
      "titulo": titulo.trim(),
      "celebrante": celebrante.trim(),
      "local": local.trim(),
      "tags": cleanTags,
      "comentarioInicial": comentarioInicial.trim(),
      "precesDaComunidade": precesDaComunidade.trim(),
      "atualizadoEm": FieldValue.serverTimestamp(),
    };

    if (observacao != null && observacao.trim().isNotEmpty) {
      docData["observacao"] = observacao.trim();
    } else {
      docData["observacao"] = FieldValue.delete();
    }

    try {
      await _collection.doc(missaId).update(docData);
    } catch (e) {
      throw Exception("Ocorreu um erro ao atualizar a missa especial: $e");
    }
  }

  Future<void> updateMissaEspecial({
    required String missaId,
    required DateTime dataHora,
    required String titulo,
    required String celebrante,
    required String local,
    String observacao = '',
    List<String> tags = const [],
  }) async {
    final tituloTrim = titulo.trim();
    final celebranteTrim = celebrante.trim();
    final localTrim = local.trim();
    final observacaoTrim = observacao.trim();

    if (tituloTrim.isEmpty || celebranteTrim.isEmpty || localTrim.isEmpty) {
      throw Exception("Título, celebrante e local são obrigatórios.");
    }

    await _validarConflitos(
      dataHora: dataHora,
      missaIdAtual: missaId,
      duracao: duracaoMinutosEspecial,
    );

    await _validarLimiteDiario(dataHora, missaIdAtual: missaId);

    final cleanTags =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final updateData = {
      "dataHora": Timestamp.fromDate(dataHora),
      "titulo": tituloTrim,
      "celebrante": celebranteTrim,
      "local": localTrim,
      "tags": cleanTags,
      "atualizadoEm": FieldValue.serverTimestamp(),
    };

    if (observacaoTrim.isNotEmpty) {
      updateData["observacao"] = observacaoTrim;
    } else {
      updateData["observacao"] = FieldValue.delete();
    }

    await _collection.doc(missaId).update(updateData);
  }

  Future<void> _validarLimiteDiario(
    DateTime dataHora, {
    String? missaIdAtual,
  }) async {
    final inicioDoDia = DateTime(
      dataHora.year,
      dataHora.month,
      dataHora.day,
      0,
      0,
      0,
    );
    final fimDoDia = DateTime(
      dataHora.year,
      dataHora.month,
      dataHora.day,
      23,
      59,
      59,
    );

    final missasDoDia =
        await _collection
            .where(
              "dataHora",
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDoDia),
            )
            .where(
              "dataHora",
              isLessThanOrEqualTo: Timestamp.fromDate(fimDoDia),
            )
            .get();

    final docsFiltrados =
        missasDoDia.docs.where((doc) => doc.id != missaIdAtual).toList();

    if (docsFiltrados.length >= maxMissasPorDia) {
      throw Exception(
        "Já existem $maxMissasPorDia missas cadastradas neste dia.",
      );
    }
  }

  Future<void> _validarConflitos({
    required DateTime dataHora,
    String? missaIdAtual,
    required int duracao,
  }) async {
    if (missaIdAtual == null && dataHora.isBefore(DateTime.now())) {
      throw Exception(
        "Não é permitido cadastrar missas em datas/horários passados.",
      );
    }

    final inicioIntervalo = dataHora.subtract(Duration(minutes: duracao));
    final fimIntervalo = dataHora.add(Duration(minutes: duracao));

    final query =
        await _collection
            .where(
              "dataHora",
              isGreaterThan: Timestamp.fromDate(inicioIntervalo),
            )
            .where("dataHora", isLessThan: Timestamp.fromDate(fimIntervalo))
            .get();

    for (var doc in query.docs) {
      if (missaIdAtual != null && doc.id == missaIdAtual) continue;
      throw Exception(
        "Já existe uma missa próxima a esse horário (mínimo $duracao minutos de intervalo).",
      );
    }
  }

  // Notificar usuários
  Future<void> notificarAgendaMensal(String nomeMes, int ano) async {
    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      );
      final callable = functions.httpsCallable('notificarAgendaMensal');

      await callable.call({'nomeMes': nomeMes, 'ano': ano});
    } catch (e) {
      throw Exception('Erro ao enviar notificação: $e');
    }
  }
}
