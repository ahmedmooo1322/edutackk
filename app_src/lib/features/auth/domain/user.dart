class User {
  const User({required this.id, required this.email, required this.displayName, required this.balance, required this.role});
  final int id; final String email; final String displayName; final int balance; final String role;
  bool get isAdmin => role == 'admin';
  factory User.fromJson(Map<String, dynamic> json) => User(id: json['id'] as int, email: json['email'] as String, displayName: json['display_name'] as String, balance: json['balance'] as int, role: json['role_code'] as String);
}

