import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/liturgia_model.dart';

class LiturgiaService {
    final String baseUrl = 'https://liturgia.up.railway.app/v2/';

  Future<Liturgia> fetchLiturgia({DateTime? data}) async {
    String url;

    if (data != null) {
      url =
          '$baseUrl?dia=${data.day}&mes=${data.month}&ano=${data.year}'; // ← aqui incluímos o ano
    } else {
      url = baseUrl; // hoje
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return Liturgia.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao carregar liturgia');
    }
  }
}