import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_login_screen/model/friends.dart';

class User {
  String email;
  String firstName;
  String lastName;
  String userID;
  String profilePictureURL;
  String appIdentifier;
  String location;
  bool isLocationVisible;
  List<Friend> friends;

  String description; // New field
  int age; // New field
  String study; // New field

  User(
      {this.email = '',
        this.firstName = '',
        this.lastName = '',
        this.userID = '',
        this.profilePictureURL = '',
        required this.isLocationVisible,
        this.location = '',
        this.friends = const <Friend>[],
        this.description = '', // Initialize new field
        this.age = 0, // Initialize new field
        this.study = ''}) // Initialize new field

      : appIdentifier =
  'Flutter Login Screen ${kIsWeb ? 'Web' : Platform.operatingSystem}';

  String fullName() => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    var friendList = parsedJson['friends'] as List?;
    List<Friend> friendsList = friendList != null
        ? friendList.map((i) => Friend.fromJson(i)).toList()
        : [];

    return User(
      email: parsedJson['email'] ?? '',
      firstName: parsedJson['firstName'] ?? '',
      lastName: parsedJson['lastName'] ?? '',
      userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
      profilePictureURL: parsedJson['profilePictureURL'] ?? '',
      isLocationVisible: parsedJson['isLocationVisible'] ?? false,
      location: parsedJson['location'] ?? '',
      friends: friendsList,
      description: parsedJson['description'] ?? '', // Parse new field
      age: parsedJson['age'] ?? 0, // Parse new field
      study: parsedJson['study'] ?? '', // Parse new field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'id': userID,
      'profilePictureURL': profilePictureURL,
      'appIdentifier': appIdentifier,
      'location': location,
      'isLocationVisible': isLocationVisible,
      'friends': friends.map((friend) => friend.toJson()).toList(),
      'description': description, // Convert new field to JSON
      'age': age, // Convert new field to JSON
      'study': study, // Convert new field to JSON
    };
  }
}
