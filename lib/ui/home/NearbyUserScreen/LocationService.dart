import 'package:geolocator/geolocator.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location service is disabled, handle accordingly
      return null;
    }

    LocationPermission permission = await GeolocatorPlatform.instance.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await GeolocatorPlatform.instance.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
    }

    return await GeolocatorPlatform.instance.getCurrentPosition();
  }

  Future<void> updateLocation(User user, FirebaseFirestore firestore) async {
    try {
      Position? position = await getCurrentPosition();
      if (position != null) {
        user.location = 'Lat: ${position.latitude}, Long: ${position.longitude}';
        await firestore.collection('users').doc(user.userID).update({
          'location': user.location,
        });
        print('Location updated: ${user.location}');  // Check if this is printed
      } else {
        print('Position is null');  // Check if this is printed
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

}
