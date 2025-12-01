class FeriadosHelper {
  // Verifica se a data é um feriado
  bool isFeriado(DateTime data) {
    // Formata dia e mês para comparar com feriados fixos (ex: "25/12")
    final String diaMes =
        "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}";

    // 1. Lista de Feriados Nacionais Fixos
    final feriadosFixos = {
      "01/01": "Ano Novo",
      "21/04": "Tiradentes",
      "01/05": "Dia do Trabalhador",
      "07/09": "Independência do Brasil",
      "12/10": "Nossa Senhora Aparecida",
      "02/11": "Finados",
      "15/11": "Proclamação da República",
      "25/12": "Natal",
      // Adicione aqui o feriado MUNICIPAL da sua cidade
      // "15/08": "Aniversário da Cidade",
    };

    if (feriadosFixos.containsKey(diaMes)) {
      return true;
    }

    // 2. Feriados Móveis (Cálculo aproximado ou manual para o ano do TCC)
    // Para TCC, é mais seguro definir manualmente os móveis deste ano e do próximo
    // do que criar algoritmos complexos de Páscoa.

    // Exemplo para 2024/2025 (Ajuste conforme necessário)
    final ano = data.year;
    if (ano == 2025) {
      final feriadosMoveis2025 = [
        DateTime(2025, 4, 18),
        // Sexta-feira Santa
        DateTime(2025, 4, 20),
        // Páscoa (Domingo, já bloqueado, mas bom constar)
        DateTime(2025, 6, 19),
        // Corpus Christi
      ];

      for (var feriado in feriadosMoveis2025) {
        if (data.day == feriado.day && data.month == feriado.month) return true;
      }
    }

    return false;
  }
}
