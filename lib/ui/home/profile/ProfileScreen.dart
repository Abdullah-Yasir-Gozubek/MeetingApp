import 'package:flutter/material.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/services/helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileScreen extends StatefulWidget {
  final User user;

  ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _ageController;
  late TextEditingController _descriptionController;
  late TextEditingController _studyController;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(text: widget.user.age.toString());
    _descriptionController = TextEditingController(text: widget.user.description);
    _studyController = TextEditingController(text: widget.user.study);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _descriptionController.dispose();
    _studyController.dispose();
    super.dispose();
  }

  // Dummy save function, replace with your Firebase save function

  Future<void> _saveUser() async {
    // parse age into an int
    int age = int.parse(_ageController.text.trim());

    // Get the description and study fields
    String description = _descriptionController.text.trim();
    String study = _studyController.text.trim();

    // Update the user object
    widget.user.age = age;
    widget.user.description = description;
    widget.user.study = study;

    // Call your Firebase function to save these details
    FirebaseFirestore.instance.collection('users').doc(widget.user.userID).update({
      'age': age,
      'description': description,
      'study': study,
    }).catchError((error) {
      // handle error here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      appBar: AppBar(
        title: Text('Profile',style: TextStyle(color: Colors.black),),
        backgroundColor: Color(0xFFEFEFEF),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            widget.user.profilePictureURL == '' ? CircleAvatar(
              radius: 100,
              backgroundColor: Colors.grey.shade400,
              child: ClipOval(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    'assets/images/placeholder.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
                : displayCircleImage(
                widget.user.profilePictureURL, 200, false),
            SizedBox(height: 20),
            Text(
              '${widget.user.firstName} ${widget.user.lastName}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
            TextField(
              controller: _studyController,
              decoration: InputDecoration(
                labelText: 'Study',
              ),
            ),
            FloatingActionButton(
              onPressed: _saveUser,
              child: Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }
}
