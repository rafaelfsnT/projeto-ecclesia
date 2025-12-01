// missa_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MissaService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'missas',
  );

  // Durações padrão (em minutos)
  final int duracaoMinutos = 60;
  final int duracaoMinutosEspecial = 90;

  // Limite de missas por dia
  final int maxMissasPorDia = 3;

  // -----------------------
  // UTILITÁRIOS PÚBLICOS
  // -----------------------

  /// Deleta todas as missas (batch)
  Future<void> deleteAllMissas() async {
    final snapshot = await _collection.get();
    if (snapshot.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Conta quantas missas existem em um dado dia (usa apenas a data)
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

  // -----------------------
  // CADASTRO - APIs compatíveis
  // -----------------------

  /// Compatibilidade: método simples que já existia (aceita DateTime completo)
  Future<void> addMissa(DateTime dataHora) async {
    final data = DateTime(dataHora.year, dataHora.month, dataHora.day);

    // Limite diário
    final count = await countMissasPorDia(data);
    if (count >= maxMissasPorDia) {
      throw Exception(
        "Limite de $maxMissasPorDia missas atingido para esta data.",
      );
    }

    // Valida conflitos com duração padrão
    await _validarConflitos(dataHora: dataHora, duracao: duracaoMinutos);

    // Insere
    await _collection.add({
      "dataHora": Timestamp.fromDate(dataHora),
      "tipo": "comum",
      "criadoEm": FieldValue.serverTimestamp(),
    });
  }

  /// API mais completa usada nas views: recebe data + TimeOfDay, escala, texto etc.
  Future<void> cadastrarMissa({
    required DateTime? data,
    required TimeOfDay? hora,
    required String local,
    required Map<String, dynamic> escala,
    required String comentario,
    required String preces,
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

    // Valida conflitos (duração normal) e limite diário
    await _validarConflitos(dataHora: dataHora, duracao: duracaoMinutos);
    await _validarLimiteDiario(dataHora);

    final docData = {
      "dataHora": Timestamp.fromDate(dataHora),
      "local": local.trim(),
      "tipo": "comum",
      "escala": escala,
      "comentarioInicial": comentario.trim(),
      "precesDaComunidade": preces.trim(),
      "criadoEm": FieldValue.serverTimestamp(),
    };

    try {
      await _collection.add(docData);
    } catch (e) {
      throw Exception("Ocorreu um erro ao salvar a missa: $e");
    }
  }

  // -----------------------
  // MISSA ESPECIAL - CADASTRO / ATUALIZAÇÃO
  // -----------------------

  /// Versão compatível que já existia (aceita DateTime completo)
  Future<void> addMissaEspecial({
    required String titulo,
    required String local,
    required String celebrante,
    required DateTime dataHora,
    String observacao = '',
    List<String> tags = const [],
    Map<String, dynamic>? escala,
    String? comentarioInicial,
    String? precesDaComunidade,
  }) async {
    final tituloTrim = titulo.trim();
    final celebranteTrim = celebrante.trim();
    final localTrim = local.trim();
    final observacaoTrim = observacao.trim();

    if (tituloTrim.isEmpty || celebranteTrim.isEmpty || localTrim.isEmpty) {
      throw Exception("Título, celebrante e local são obrigatórios.");
    }

    final data = DateTime(dataHora.year, dataHora.month, dataHora.day);
    final count = await countMissasPorDia(data);
    if (count >= maxMissasPorDia) {
      throw Exception(
        "Limite de $maxMissasPorDia missas atingido para este dia.",
      );
    }

    await _validarConflitos(
      dataHora: dataHora,
      duracao: duracaoMinutosEspecial,
    );

    final cleanTags =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final docData = {
      "dataHora": Timestamp.fromDate(dataHora),
      "titulo": tituloTrim,
      "celebrante": celebranteTrim,
      "local": localTrim,
      if (observacaoTrim.isNotEmpty) "observacao": observacaoTrim,
      "tags": cleanTags,
      "tipo": "especial",
      if (escala != null) "escala": escala,
      if (comentarioInicial != null) "comentarioInicial": comentarioInicial,
      if (precesDaComunidade != null) "precesDaComunidade": precesDaComunidade,
      "criadoEm": FieldValue.serverTimestamp(),
    };

    await _collection.add(docData);
  }

  /// Versão usada nas views: recebe data + TimeOfDay e mais campos
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
    };

    try {
      await _collection.add(docData);
    } catch (e) {
      throw Exception("Ocorreu um erro ao salvar a missa especial: $e");
    }
  }

  // -----------------------
  // EDIÇÕES
  // -----------------------

  /// Edição simples quando você já tem DateTime completo (mantive compatibilidade)
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

  /// Edição completa (usada nas views que enviam data + TimeOfDay e campos)
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

  /// Edição específica para missas especiais (recebe date + time + campos)
  /// OBS: este método existe e exige novaData + novaHora + comentário/preces.
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

    // Lida com observacao – remove se vazio
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

  /// ----- NOVO: Alias/compatibilidade -----
  /// Método `updateMissaEspecial` adicionado para compatibilidade com a UI
  /// que chama exatamente esse nome e passa um único DateTime (dataHora).
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

    // Valida conflitos considerando duração de missa especial
    await _validarConflitos(
      dataHora: dataHora,
      missaIdAtual: missaId,
      duracao: duracaoMinutosEspecial,
    );

    // Valida limite diário (não conta a missa que está sendo editada)
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

  // -----------------------
  // MÉTODOS PRIVADOS (VALIDAÇÕES)
  // -----------------------

  /// Valida número máximo de missas por dia (não conta a missa em edição, se passada)
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
    // [CORREÇÃO AQUI]
    // Esta validação agora só roda para NOVAS missas (quando missaIdAtual é nulo)
    // Isso permite que você edite missas que já passaram.
    if (missaIdAtual == null && dataHora.isBefore(DateTime.now())) {
      throw Exception(
        "Não é permitido cadastrar missas em datas/horários passados.",
      );
    }

    // Calcula intervalo que deve estar livre
    final inicioIntervalo = dataHora.subtract(Duration(minutes: duracao));
    final fimIntervalo = dataHora.add(Duration(minutes: duracao));

    // Consulta por documentos cuja dataHora esteja no intervalo (maior que inicioIntervalo e menor que fimIntervalo)
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
      // Se existir qualquer doc no intervalo, considera conflito
      throw Exception(
        "Já existe uma missa próxima a esse horário (mínimo $duracao minutos de intervalo).",
      );
    }
  }
}
