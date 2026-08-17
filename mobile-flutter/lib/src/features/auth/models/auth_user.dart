class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: int.parse(json['id'].toString()),
      name: json['name'].toString(),
      email: json['email'].toString(),
      role: json['role'].toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }
}
