class ProviderProfile {
  final String id;
  final String fullName;
  final int? starLevel;
  final String? bio;
  final List<String> skills;
  final bool verified;
  final bool contactUnlocked;
  final String? email; // only present when contactUnlocked is true
  final String? phone; // only present when contactUnlocked is true

  ProviderProfile({
    required this.id,
    required this.fullName,
    this.starLevel,
    this.bio,
    required this.skills,
    required this.verified,
    required this.contactUnlocked,
    this.email,
    this.phone,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> json) => ProviderProfile(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        starLevel: json['starLevel'] as int?,
        bio: json['bio'] as String?,
        skills: (json['skills'] as List?)?.map((e) => e as String).toList() ?? [],
        verified: json['verified'] as bool? ?? false,
        contactUnlocked: json['contactUnlocked'] as bool? ?? false,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
      );
}
