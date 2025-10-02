enum UserRole { admin, inspector }

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String nationalId;
  final String rank;
  final UserRole role;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.nationalId,
    required this.rank,
    required this.role,
    this.avatarUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) {
    return AppUser(
      id: m['id'] as String,
      email: (m['email'] as String?) ?? '',
      fullName: (m['full_name'] as String?) ?? '',
      nationalId: (m['national_id'] as String?) ?? '',
      rank: (m['rank'] as String?) ?? '',
      role: ((m['role'] as String?) ?? 'inspector') == 'admin'
          ? UserRole.admin
          : UserRole.inspector,
      avatarUrl: m['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toUpdate() => {
        'full_name': fullName,
        'national_id': nationalId,
        'rank': rank,
        'avatar_url': avatarUrl,
      };

  AppUser copyWith({
    String? fullName,
    String? nationalId,
    String? rank,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      rank: rank ?? this.rank,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
