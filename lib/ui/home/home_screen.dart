import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_screen/constants.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/services/helper.dart';
import 'package:flutter_login_screen/ui/auth/authentication_bloc.dart';
import 'package:flutter_login_screen/ui/auth/welcome/welcome_screen.dart';
import 'package:flutter_login_screen/ui/home/NearbyUserScreen/NearbyUserScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_login_screen/ui/home/chat/ChatScreen.dart';
import 'package:flutter_login_screen/ui/home/profile/ProfileScreen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter_login_screen/ui/home/notification/NotificationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  late User user;
  Position? currentPosition;
  final FirebaseFirestore firestore = FirebaseFirestore
      .instance; // Create Firestore instance
  late List<Widget> _children;


  @override
  void initState() {
    super.initState();
    user = widget.user;
    _getLocation();
    _fetchCurrentLocation();
    String chatUserId = 'predefinedChatUserId'; // Define a pre-determined chatUserId here
    _children = [
      NearbyUserScreen(user: user),
      ChatScreen(), // user.userID is the logged in user's ID
      NotificationScreen(),
      ProfileScreen(user: user),  // Add ProfileScreen to _children
    ];
  }

  void updateVisibility(bool isVisible) async {
    user.isLocationVisible = isVisible;
    await firestore.collection('users').doc(user.userID).update({
      'isLocationVisible': user.isLocationVisible,
    });
    setState(() {}); // Notify Flutter to update the UI
  }

  void _fetchCurrentLocation() async {
    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    updateLocation(currentPosition!.latitude, currentPosition!.longitude);
  }

  void updateLocation(double latitude, double longitude) async {
    user.location = 'Lat: $latitude, Long: $longitude';
    await firestore.collection('users').doc(user.userID).update({
      'location': user.location,
    });
    setState(() {}); // Notify Flutter to update the UI
  }

  void getLocation() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location service is disabled, handle accordingly
      return;
    }


    // Request permission to access the location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      // Permission is denied forever, handle accordingly
      return;
    }

    if (permission == LocationPermission.denied) {
      // Permission is denied, request permission
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Permission is denied, handle accordingly
        return;
      }
    }

    // Get the current position (longitude and latitude)
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // Update currentPosition
    setState(() {
      currentPosition = position;
    });

    // Display the longitude and latitude
    print('Longitude: ${position.longitude}');
    print('Latitude: ${position.latitude}');

    // Update location to firestore
    updateLocation(position.latitude, position.longitude);
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition();
  }


  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
        backgroundColor: Color(0xFFEFEFEF),
        // drawer: Drawer(
        //   child: ListView(
        //     padding: EdgeInsets.zero,
        //     children: [
        //       DrawerHeader(
        //         decoration: BoxDecoration(
        //           color: Color(colorPrimary),
        //         ),
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: <Widget>[
        //             Text(
        //               'Profile',
        //               style: TextStyle(color: Colors.white),
        //             ),
        //             SizedBox(height: 20),
        //             Row(
        //               children: [
        //                 user.profilePictureURL == ''
        //                     ? CircleAvatar(
        //                   radius: 35,
        //                   backgroundColor: Colors.grey.shade400,
        //                   child: ClipOval(
        //                     child: SizedBox(
        //                       width: 70,
        //                       height: 70,
        //                       child: Image.asset(
        //                         'assets/images/placeholder.jpg',
        //                         fit: BoxFit.cover,
        //                       ),
        //                     ),
        //                   ),
        //                 )
        //                     : displayCircleImage(
        //                     user.profilePictureURL, 80, false),
        //                 SizedBox(width: 10),
        //                 Text(
        //                   user.fullName(),
        //                   style: TextStyle(color: Colors.white),
        //                 ),
        //               ],
        //             ),
        //           ],
        //         ),
        //       ),
        //       ListTile(
        //         title: Text(
        //           'Logout',
        //           style: TextStyle(
        //               color: isDarkMode(context)
        //                   ? Colors.grey.shade50
        //                   : Colors.grey.shade900),
        //         ),
        //         leading: Transform.rotate(
        //           angle: pi / 1,
        //           child: Icon(
        //             Icons.exit_to_app,
        //             color: isDarkMode(context)
        //                 ? Colors.grey.shade50
        //                 : Colors.grey.shade900,
        //           ),
        //         ),
        //         onTap: () {
        //           context.read<AuthenticationBloc>().add(LogoutEvent());
        //         },
        //       ),
        //     ],
        //   ),
        // ),
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _children,
            ),
            // Custom Top Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Builder(  // Builder is used to access Scaffold.of(context) for the drawer
                    //   builder: (context) => IconButton(
                    //     icon: Icon(
                    //       Icons.menu,
                    //       color: isDarkMode(context)
                    //           ? Colors.grey.shade50
                    //           : Colors.grey.shade900,
                    //     ),
                    //     onPressed: () => Scaffold.of(context).openDrawer(),
                    //   ),
                    // ),
                    // Switch(
                    //   value: user.isLocationVisible,
                    //   onChanged: (value) {
                    //     updateVisibility(value);
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),  // Adding borderRadius
            boxShadow: [
              BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,  // Set the background color to white
              unselectedItemColor: Colors.black,  // Unselected items will be black
              selectedItemColor: Colors.amber[800],  // Selected item color
              showSelectedLabels: false,  // This hides the label when the item is selected
              showUnselectedLabels: false,  // This hides the label when the item is unselected
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.home),
                  label: 'Nearby User',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.comments),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.bell),
                  label: 'Notification',
                ),
                BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.userCircle),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            )
          ),
        ),
      ),
    );
  }
}