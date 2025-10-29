// models/user_model.dart
class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? about;
  final String? gender;
  final String? birthday;
  final String? country;
  final String? phoneNumber;
  final double balance;
  final bool verified;
  final bool active;
  final bool isPro;
  final String registered;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.about,
    this.gender,
    this.birthday,
    this.country,
    this.phoneNumber,
    required this.balance,
    required this.verified,
    required this.active,
    required this.isPro,
    required this.registered,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatar: json['avater'],
      about: json['about'],
      gender: json['gender'],
      birthday: json['birthday'],
      country: json['country'],
      phoneNumber: json['phone_number'],
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      verified: (json['verified'] ?? '0') == '1',
      active: (json['active'] ?? '0') == '1',
      isPro: (json['is_pro'] ?? '0') == '1',
      registered: json['registered'] ?? '',
    );
  }
}

class ReferredUser {
  final String userId;
  final String username;
  final String email;
  final String? avatar;
  final String joinedDate;

  ReferredUser({
    required this.userId,
    required this.username,
    required this.email,
    this.avatar,
    required this.joinedDate,
  });

  factory ReferredUser.fromJson(Map<String, dynamic> json) {
    return ReferredUser(
      userId: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avater'],
      joinedDate: json['registered'] ?? '',
    );
  }
}