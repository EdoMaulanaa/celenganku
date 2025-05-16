class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Constructor
  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });
  
  // Create from Supabase JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
  
  // Copy with method for updating
  UserProfile copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 