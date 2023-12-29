import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/model/message.dart';
import 'package:rxdart/rxdart.dart';


class UserChatScreen extends StatefulWidget {

  final User user;
  final String currentUserId;

  UserChatScreen({required this.user, required this.currentUserId});

  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}


class _UserChatScreenState extends State<UserChatScreen> {
  final messageController = TextEditingController();
  late Stream<List<QueryDocumentSnapshot>> messagesStream;

  @override
  void initState() {
    super.initState();

    Stream<QuerySnapshot> outgoingMessagesStream = FirebaseFirestore.instance.collection('messages')
        .where('senderID', isEqualTo: widget.currentUserId)
        .where('receiverID', isEqualTo: widget.user.userID)
        .snapshots();

    Stream<QuerySnapshot> incomingMessagesStream = FirebaseFirestore.instance.collection('messages')
        .where('senderID', isEqualTo: widget.user.userID)
        .where('receiverID', isEqualTo: widget.currentUserId)
        .snapshots();

    messagesStream = Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<QueryDocumentSnapshot>>(
      outgoingMessagesStream,
      incomingMessagesStream,
          (outgoingSnap, incomingSnap) {
        return List.from(outgoingSnap.docs)..addAll(incomingSnap.docs);
      },
    ).map((messageDocs) {
      messageDocs.sort((a, b) => b.get('timestamp').compareTo(a.get('timestamp')));
      return messageDocs;
    });
  }

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('messages').add(
        Message(
          senderID: widget.currentUserId,
          receiverID: widget.user.userID,
          content: messageController.text,
          timestamp: Timestamp.now(),
        ).toJson(),
      );
      messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
          title: Text(
              'Chat with ${widget.user.firstName}',
              style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFEFEFEF),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Message message = Message.fromJson(snapshot.data![index].data() as Map<String, dynamic>);
                    bool isSender = widget.currentUserId == message.senderID;
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65,
                            ),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSender ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color: isSender ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  message.timestamp.toDate().toString(),
                                  style: TextStyle(
                                    color: isSender ? Colors.white60 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
