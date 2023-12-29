import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/ui/home/chat/UserChatScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isDataLoaded = false;
  List<User> users = [];
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    getCurrentUserId().then((_) {
      fetchFriendsInfo();
    });
  }


  Future<void> getCurrentUserId() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.FirebaseAuth.instance.currentUser?.uid)
        .get();

    setState(() {
      currentUserId = userDoc.data()?['id'] ?? '';
    });
  }

  void fetchFriendsInfo() async {
    final friendsDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .where('accepted', isEqualTo: true)
        .get();

    for (final friendDoc in friendsDocs.docs) {
      final friendId = friendDoc.id;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();

      final user = User.fromJson(userDoc.data() as Map<String, dynamic>);
      users.add(user);
    }

    setState(() {
      isDataLoaded = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (!isDataLoaded) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF), // this is the background color
      appBar: AppBar(
        title: Text(
          'Chat Users',
          style: TextStyle(color: Colors.black),  // Setting the text color to black
        ),
        backgroundColor: Color(0xFFEFEFEF), // AppBar color
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          User user = users[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 4.0),
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1), // Border color and width
              color: Colors.white, // Inside color
              borderRadius: BorderRadius.circular(10), // Border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.profilePictureURL),
               // child: Text(user.firstName.substring(0, 2).toUpperCase()),
              ),
              title: Text('${user.firstName} '),
              //subtitle: Text(user.email),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserChatScreen(user: user, currentUserId: currentUserId),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}