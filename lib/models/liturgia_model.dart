class TextoLiturgico {
  final String referencia;
  final String? titulo; // Alguns têm título, outros não
  final String? refrao; // Para salmo
  final String texto;

  TextoLiturgico({
    required this.referencia,
    this.titulo,
    this.refrao,
    required this.texto,
  });

  factory TextoLiturgico.fromJson(Map<String, dynamic> json) {
    return TextoLiturgico(
      referencia: json['referencia'],
      titulo: json['titulo'],
      refrao: json['refrao'],
      texto: json['texto'],
    );
  }
}

class Liturgia {
  final String data;
  final String liturgia;
  final String cor;
  final List<TextoLiturgico> primeiraLeitura;
  final List<TextoLiturgico> segundaLeitura;
  final List<TextoLiturgico> salmo;
  final List<TextoLiturgico> evangelho;
 
  Liturgia({
    required this.data,
    required this.liturgia,
    required this.cor,
    required this.primeiraLeitura,
    required this.segundaLeitura,
    required this.salmo,
    required this.evangelho,
  });

  factory Liturgia.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(List? items, T Function(Map<String, dynamic>) creator) {
      return (items ?? []).map<T>((e) => creator(e)).toList();
    }

    return Liturgia(
      data: json['data'],
      liturgia: json['liturgia'],
      cor: json['cor'],
      primeiraLeitura: parseList(json['leituras']['primeiraLeitura'], TextoLiturgico.fromJson),
      segundaLeitura: parseList(json['leituras']['segundaLeitura'], TextoLiturgico.fromJson),
      salmo: parseList(json['leituras']['salmo'], TextoLiturgico.fromJson),
      evangelho: parseList(json['leituras']['evangelho'], TextoLiturgico.fromJson),
    );
  }
}
