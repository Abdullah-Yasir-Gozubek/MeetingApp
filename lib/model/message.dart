import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String senderID;
  String receiverID;
  String content;
  Timestamp timestamp;

  Message({
    required this.senderID,
    required this.receiverID,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> parsedJson) {
    return Message(
      senderID: parsedJson['senderID'] ?? '',
      receiverID: parsedJson['receiverID'] ?? '',
      content: parsedJson['content'] ?? '',
      timestamp: parsedJson['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderID': senderID,
      'receiverID': receiverID,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
