import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_login_screen/model/user.dart';

class AppNotification {
  String? notificationId; // ID of the notification
  String? title;
  String? body;
  String? messageId; // ID of the message
  DateTime? sentTime; // Time when the message was sent
  String? recipientId; // ID of the recipient
  String? senderId; // ID of the sender

  AppNotification({this.notificationId, this.title, this.body, this.messageId, this.sentTime, this.recipientId, this.senderId});

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'messageId': messageId,
      'sentTime': sentTime?.millisecondsSinceEpoch,
      'recipientId': recipientId,
      'senderId': senderId, // <-- Add this
    };
  }

  void addNotificationToFirestore() {
    final firestoreInstance = FirebaseFirestore.instance;

    firestoreInstance.collection("users").doc(recipientId).collection("notifications").add(
        this.toJson()
    ).then((_) {
      print("Notification added to Firestore");
    }).catchError((error) {
      print("Failed to add notification: $error");
    });
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'],
      title: json['title'],
      body: json['body'],
      messageId: json['messageId'],
      sentTime: DateTime.fromMillisecondsSinceEpoch(json['sentTime'] as int? ?? 0),
      recipientId: json['recipientId'],
      senderId: json['senderId'], // <-- Add this
    );
  }
}