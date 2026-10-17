class AppUser {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String role; // 'CUSTOMER' | 'PROVIDER'

  AppUser({required this.id, required this.email, this.phone, required this.fullName, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
      );
}
