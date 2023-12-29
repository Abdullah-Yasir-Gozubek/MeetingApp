import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_screen/constants.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/model/notification.dart';
import 'package:flutter_login_screen/services/helper.dart';
import 'package:flutter_login_screen/ui/auth/authentication_bloc.dart';
import 'package:flutter_login_screen/ui/auth/welcome/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_login_screen/ui/home/chat/ChatScreen.dart';
import 'package:flutter_login_screen/ui/home/chat/UserChatScreen.dart';
import 'package:flutter_login_screen/ui/home/notification/NotificationScreen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_login_screen/ui/home/NearbyUserScreen/LocationService.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class NearbyUserScreen extends StatefulWidget {
  final User user;

  const NearbyUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  State createState() => _NearbyUserState();
}

class _NearbyUserState extends State<NearbyUserScreen> {
  late User user;
  Position? currentPosition;
  String currentUserId = '';
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Color buttonColor = Colors.red;
  String buttonText = "Inactive";
  LatLng? _userLatLng;
  final LocationService _locationService = LocationService();

  late PageController _slideController;
  int currentSlide = 0;
  Timer? _slideTimer;
  List<Map<String, String>> slides = [
    {
      'text': 'Every Look Holds a Love Story',
      'imagePath': 'assets/images/mainslide.jpg',
    },
    {
      'text': 'Send Emoji Now 😍',
      'imagePath': 'assets/images/secondslide.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    user = widget.user;
    _initializeLocation();

    // Initialization for the slideshow:
    _slideController = PageController();

    _slideTimer = Timer.periodic(Duration(seconds: 4), (Timer timer) {
      if (currentSlide < slides.length - 1) {
        currentSlide++;
      } else {
        currentSlide = 0;
      }

      _slideController.animateToPage(
        currentSlide,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  _initializeLocation() async {
    currentPosition = await _locationService.getCurrentPosition();
    if (currentPosition != null) {
      await _locationService.updateLocation(user, firestore);
      setState(() {});
    }
  }

  void updateVisibility(bool isVisible) async {
    user.isLocationVisible = isVisible;
    await firestore.collection('users').doc(user.userID).update({
      'isLocationVisible': user.isLocationVisible,
    });
    setState(() {});
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> acceptFriendRequest(String currentUserId, String otherUserId) async {
    final firestoreInstance = FirebaseFirestore.instance;

    // Add otherUserId to current user's friends
    await firestoreInstance.collection('users').doc(currentUserId).collection('friends').doc(otherUserId).set({});

    // Add currentUserId to other user's friends
    await firestoreInstance.collection('users').doc(otherUserId).collection('friends').doc(currentUserId).set({});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.authState == AuthState.unauthenticated) {
          pushAndRemoveUntil(context, const WelcomeScreen(), false);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFEFEFEF), Color(0xFFEFEFEF)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          // User profile image with added functionality
                          PopupMenuButton<int>(
                            onSelected: (item) {
                              if (item == 0) {
                                context.read<AuthenticationBloc>().add(LogoutEvent());
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<int>(
                                value: -1,  // An arbitrary value to represent the username. We don't need an onSelected action for this item.
                                child: Text(
                                  '${widget.user.firstName} ${widget.user.lastName}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade50
                                        : Colors.grey.shade900,
                                  ),
                                ),
                                enabled: false,  // Making sure this menu item isn't selectable
                              ),
                              PopupMenuItem<int>(
                                value: 0,
                                child: Row(
                                  children: [
                                    Transform.rotate(
                                      angle: pi / 1,
                                      child: Icon(
                                        Icons.exit_to_app,
                                        color: isDarkMode(context)
                                            ? Colors.grey.shade50
                                            : Colors.grey.shade900,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                          color: isDarkMode(context)
                                              ? Colors.grey.shade50
                                              : Colors.grey.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          child: Container(
                            padding: EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade400,
                              child: user.profilePictureURL == ''
                                  ? ClipOval(
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Image.asset(
                                    'assets/images/placeholder.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                                  : displayCircleImage(user.profilePictureURL, 80, false),
                            ),
                          ),
                        ),
                        SizedBox(width: 16), // spacing after user image

                        // "People Nearby" text
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'hi!  ',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,  // Assuming black, but you can adjust this
                                  ),
                                ),
                                TextSpan(
                                  text: user.firstName,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,  // Assuming black, but you can adjust this
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Spacer(), // This will push the following items to the end of the Row

                          // Visible/Invisible Button
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Toggle visibility
                                if (buttonText == "Inactive") {
                                  buttonText = "Active";
                                  updateVisibility(true);
                                } else {
                                  buttonText = "Inactive";
                                  updateVisibility(false);
                                }
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Using conditional expression to determine which icon to show
                                (buttonText == "Active")
                                    ? Icon(Icons.circle, color: Colors.green, size: 14)
                                    : Icon(Icons.circle, color: Colors.red, size: 14),
                                SizedBox(width: 6), // For some spacing between icon and text
                                Text(buttonText),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                              onPrimary: (buttonText == "Active") ? Colors.green : Colors.red,
                              shape: RoundedRectangleBorder(  // Rounded rectangle shape
                                borderRadius: BorderRadius.circular(24.0),
                                side: BorderSide(color: Colors.grey.shade400, width: 2),  // Gray border around the button
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),  // Padding for the text and icon inside
                            ),
                          ),
                          SizedBox(width: 16),// spacing after the button
                          // Notification icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                            ),
                            child: Center(
                              child: Icon(Icons.notifications, color: Colors.grey.shade600, size: 25),
                            ),
                          ),

                          SizedBox(width: 16),// spacing after notification icon
             ],
            ),
          ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                      child: Text(
                        "Find People Nearby",
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // The Google Maps widget replaced by the Slideshow
                    Container(
                      height: 200,
                      child: PageView.builder(
                        controller: _slideController,
                        itemCount: slides.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  image: AssetImage(slides[index]['imagePath']!),
                                  fit: BoxFit.cover, // You can adjust this as needed
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  slides[index]['text']!,
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    color: index == 1 ? Colors.black : Colors.red.shade900,  // Check for the second slide and change its color to black
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),



                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                spreadRadius: 0.1,
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              await _locationService.updateLocation(user, firestore);
                              setState(() {});
                            },
                            child: Text('Find Nearby People'),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFF1B9A8B),
                              onPrimary: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),


                  StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('users').snapshots(),
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Something went wrong');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text("Searching");
                      }

                      return Wrap(
                        spacing: 16.0, // gap between adjacent chips, adjust as needed
                        runSpacing: 16.0, // gap between lines, adjust as needed
                        children: snapshot.data!.docs
                            .where((document) => document['id'] != user.userID && document['isLocationVisible'] == true)
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                          String locationString = data['location'] ?? "0,0";
                          List<String> splitLocation = locationString.split(",");
                          double lat = 0;
                          double lon = 0;
                          if (splitLocation.length == 2) {
                            lat = double.parse(splitLocation[0].split(":")[1].trim());
                            lon = double.parse(splitLocation[1].split(":")[1].trim());
                          }
                          double distanceInMeters = currentPosition != null
                              ? GeolocatorPlatform.instance.distanceBetween(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                            lat,
                            lon,
                          )
                              : 0;

                          bool isNear = distanceInMeters <= 500;

                          if (isNear) {
                            return Container(
                          width: MediaQuery.of(context).size.width * 0.5-32,  // Calculate width based on screen width
                          child: InkWell(
                          onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      insetPadding: EdgeInsets.all(10),
                                      child: Container(
                                        height: 450, // adjust the size as needed
                                        width: 350, // adjust the size as needed
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              data['profilePictureURL'] ?? 'assets/images/placeholder.jpg',
                                            ),
                                            fit: BoxFit.cover,
                                            //colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.dstATop),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${data['firstName']} ${data['lastName'] ?? ""}',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Nunito Sans',
                                                  fontSize: 20, // Adjust this value as needed
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,  // This is the location icon
                                                    color: Colors.white,
                                                  ),
                                                  Text(
                                                    '${distanceInMeters.toStringAsFixed(2)} m',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      String otherUserId = data['id'];
                                                      acceptFriendRequest(user.userID, otherUserId);

                                                      String notificationText = '${user.fullName()} sent 😀 ${data['firstName']} ${data['lastName'] ?? ""}';

                                                      AppNotification newNotification = AppNotification(
                                                        title: "😀 sent",
                                                        body: notificationText,
                                                        messageId: data['messageId'], // replace with your message id logic
                                                        sentTime: DateTime.now(),
                                                        senderId: user.userID,
                                                        recipientId: otherUserId, // id of the user receiving the notification
                                                      );
                                                      newNotification.addNotificationToFirestore();
                                                    },
                                                    child: Text('😀', style: TextStyle(fontSize: 24)),
                                                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      String otherUserId = data['id'];
                                                      acceptFriendRequest(user.userID, otherUserId);

                                                      String notificationText = '${user.fullName()} sent 😉 ${data['firstName']} ${data['lastName'] ?? ""}';

                                                      AppNotification newNotification = AppNotification(
                                                        title: "😉 sent",
                                                        body: notificationText,
                                                        messageId: data['messageId'], // replace with your message id logic
                                                        sentTime: DateTime.now(),
                                                        senderId: user.userID,
                                                        recipientId: otherUserId, // id of the user receiving the notification
                                                      );
                                                      newNotification.addNotificationToFirestore();                                                    },
                                                    child: Text('😉', style: TextStyle(fontSize: 24)),
                                                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      String otherUserId = data['id'];
                                                      acceptFriendRequest(user.userID, otherUserId);

                                                      String notificationText = '${user.fullName()} sent 😍 ${data['firstName']} ${data['lastName'] ?? ""}';

                                                      AppNotification newNotification = AppNotification(
                                                        title: "😍 sent",
                                                        body: notificationText,
                                                        messageId: data['messageId'], // replace with your message id logic
                                                        sentTime: DateTime.now(),
                                                        senderId: user.userID,
                                                        recipientId: otherUserId, // id of the user receiving the notification
                                                      );
                                                      newNotification.addNotificationToFirestore();                                                    },
                                                    child: Text('😍', style: TextStyle(fontSize: 24)),
                                                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                          child: Container(
                          width: 250.0,
                          height: 300.0,
                          margin: EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow: [
                          BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 0.1,
                          blurRadius: 5,
                          offset: Offset(3, 3),// Shadow moves 10 points to right and 10 points to the bottom
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              data['profilePictureURL'] ?? 'assets/images/placeholder.jpg',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.circular(30.0), // Make sure this matches the parent Container
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 120.0,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10.0), // adjust to match parent Container
                                          bottomRight: Radius.circular(10.0), // adjust to match parent Container
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                                      child: Stack(
                                        children: [
                                          Align(
                                            alignment: Alignment.topCenter,
                                            child: Text(
                                              '${data['firstName']} ${data['lastName'] ?? ""}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,  // This will make the text bold
                                                color: Colors.white,
                                                fontFamily: 'Nunito Sans',
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Container(
                                              margin: EdgeInsets.only(top: 4),  // Add some margin if necessary
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6), // Adjust opacity as necessary
                                                borderRadius: BorderRadius.circular(20.0),  // This makes the container oval
                                              ),
                                              child: Text(
                                                '${distanceInMeters.toStringAsFixed(2)} m',
                                                style: TextStyle(color: Colors.white, fontFamily: 'Nunito Sans'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ),
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
