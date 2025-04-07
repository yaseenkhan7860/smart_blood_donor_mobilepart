class User {
  final String id;
  final String email;
  final String name;
  final String? bloodGroup;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.bloodGroup,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      name: json['name'],
      bloodGroup: json['bloodGroup'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bloodGroup': bloodGroup,
      'createdAt': createdAt,
    };
  }
} 