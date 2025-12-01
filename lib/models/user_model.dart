class UserModel {
  final String uid;
  final String email;
  final String nome;
  final String categoria;
  final String? role; // Pode ser nulo se o usuário não for admin

  UserModel({
    required this.uid,
    required this.email,
    required this.nome,
    required this.categoria,
    this.role,
  });
}