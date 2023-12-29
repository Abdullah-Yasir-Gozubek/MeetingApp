import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'NotificationProvider.dart';
import 'package:flutter_login_screen/model/notification.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/model/friends.dart';
import 'package:flutter_login_screen/ui/home/NearbyUserScreen/NearbyUserScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  StreamSubscription<QuerySnapshot>? notificationSubscription;

  @override
  void initState() {
    super.initState();

    final FirebaseAuth auth = FirebaseAuth.instance;
    String userId = auth.currentUser != null ? auth.currentUser!.uid : "";

    if (userId.isNotEmpty) {
      final firestoreInstance = FirebaseFirestore.instance;
      notificationSubscription = firestoreInstance.collection("users").doc(userId).collection("notifications").orderBy('sentTime', descending: true).snapshots().listen((snapshot) {
        fetchNotifications();
        Provider.of<NotificationProvider>(context, listen: false).clearNotifications();

      });
    } else {
      print("Unable to setup notification listener: No current user");
    }
  }


  @override
  void dispose() {
    notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> acceptFriendRequest(String currentUserId, String otherUserId, String notificationId) async {
    final firestoreInstance = FirebaseFirestore.instance;

    // Add otherUserId to current user's friends and set accepted to true
    await firestoreInstance.collection('users').doc(currentUserId).collection('friends').doc(otherUserId).set({'accepted': true});

    // Add currentUserId to other user's friends and set accepted to true
    await firestoreInstance.collection('users').doc(otherUserId).collection('friends').doc(currentUserId).set({'accepted': true});

    // Remove the notification from the current user's notifications
    await firestoreInstance.collection('users').doc(currentUserId).collection('notifications').doc(notificationId).delete();
  }


  fetchNotifications() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    String userId = auth.currentUser != null ? auth.currentUser!.uid : "";

    if (userId.isNotEmpty) {
      final firestoreInstance = FirebaseFirestore.instance;

      firestoreInstance.collection("users").doc(userId).collection("notifications").orderBy('sentTime', descending: true).get().then((querySnapshot) {
        Provider.of<NotificationProvider>(context, listen: false).clearNotifications();  // clear the notifications list

        querySnapshot.docs.forEach((result) {
          print(result.data()); // for debugging
          var notification = AppNotification.fromJson(result.data());
          Provider.of<NotificationProvider>(context, listen: false).addNotification(result.id, notification);
        });
      });
    } else {
      print("Unable to fetch notifications: No current user");
    }
  }




  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
        title: Text('Notification Screen', style: TextStyle(color: Colors.black),),
        backgroundColor: Color(0xFFEFEFEF),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              var id = provider.notifications.keys.elementAt(index);
              var notification = provider.notifications[id]!;
              return ListTile(
                title: Text(notification.body!),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // Shrink the row to the size of its children
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        // Handle accept logic here
                        print('Request Accepted');
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        String currentUserId = auth.currentUser != null ? auth.currentUser!.uid : "";
                        if (currentUserId.isNotEmpty && notification.senderId != null) {
                          await acceptFriendRequest(currentUserId, notification.senderId!, id);
                          Provider.of<NotificationProvider>(context, listen: false).removeNotification(id);
                        } else {
                          print("Unable to accept friend request: No current user");
                        }
                      },
                      child: Text('Accept'),
                    ),
                    SizedBox(width: 10), // Add some spacing between the buttons
                    ElevatedButton(
                      onPressed: () {
                        // Handle decline logic here
                        print('Request Declined');
                      },
                      child: Text('Decline'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}




