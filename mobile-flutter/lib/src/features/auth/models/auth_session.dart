import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  final AuthUser user;
  final String token;
  final String tokenType;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'].toString(),
      tokenType: json['token_type']?.toString() ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'token': token, 'token_type': tokenType};
  }
}
