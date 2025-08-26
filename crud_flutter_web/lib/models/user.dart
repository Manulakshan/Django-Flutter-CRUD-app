class User {
  final int? id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final int? age;
  final String? profilePicture; 

  User({
    this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    this.age,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      address: json['address'],
      age: json['age'] is int ? json['age'] : (json['age'] != null ? int.tryParse('${json['age']}') : null),
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'age': age,
      // profile_picture intentionally omitted for JSON requests (use multipart when uploading files)
    };
  }
}