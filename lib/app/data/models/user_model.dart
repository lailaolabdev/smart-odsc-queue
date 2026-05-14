import 'dart:convert';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String userName;
  final String userType;
  final String gender;
  final String? profileImage;
  final String userStatus;
  final String? lastLogin;
  final int? loginAttempts;
  final String? dateOfBirth;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;
  final dynamic officerProfile;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.userName,
    required this.userType,
    required this.gender,
    this.profileImage,
    required this.userStatus,
    this.lastLogin,
    this.loginAttempts,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.officerProfile,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json["id"],
    firstName: json["firstName"],
    lastName: json["lastName"],
    phoneNumber: json["phoneNumber"],
    email: json["email"],
    userName: json["userName"],
    userType: json["userType"],
    gender: json["gender"],
    profileImage: json["profileImage"],
    userStatus: json["userStatus"],
    lastLogin: json["lastLogin"],
    loginAttempts: json["loginAttempts"],
    dateOfBirth: json["dateOfBirth"],
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    createdBy: json["createdBy"],
    updatedBy: json["updatedBy"],
    officerProfile: json["officerProfile"],
    accessToken: json["accessToken"],
    refreshToken: json["refreshToken"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "firstName": firstName,
    "lastName": lastName,
    "phoneNumber": phoneNumber,
    "email": email,
    "userName": userName,
    "userType": userType,
    "gender": gender,
    "profileImage": profileImage,
    "userStatus": userStatus,
    "lastLogin": lastLogin,
    "loginAttempts": loginAttempts,
    "dateOfBirth": dateOfBirth,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "createdBy": createdBy,
    "updatedBy": updatedBy,
    "officerProfile": officerProfile,
    "accessToken": accessToken,
    "refreshToken": refreshToken,
  };

  String get fullName => '$firstName $lastName';
}
