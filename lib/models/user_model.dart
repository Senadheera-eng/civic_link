import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String userType;
  final String profilePicture;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.userType,
    this.profilePicture = '',
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      userType: data['userType'] ?? 'citizen',
      profilePicture: data['profilePicture'] ?? '',
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'userType': userType,
      'profilePicture': profilePicture,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  bool get isAdmin => userType == 'admin';
  bool get isCitizen => userType == 'citizen';
}
