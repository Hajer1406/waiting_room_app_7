enum UserRole {
  staff,
  client,
}

extension UserRoleExtension on UserRole {
  String get displayName => this == UserRole.staff ? 'Agent / Staff' : 'Client / Patient';
  bool get isStaff => this == UserRole.staff;
  bool get isClient => this == UserRole.client;
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.client,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final roleStr = (map['role'] as String?)?.toLowerCase() ?? 'client';
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ??
          (map['email'] as String? ?? 'User').split('@').first,
      role: (roleStr == 'staff' || roleStr == 'agent' || roleStr == 'admin')
          ? UserRole.staff
          : UserRole.client,
    );
  }
}
