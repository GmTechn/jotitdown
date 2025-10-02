import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notesapp/components/mybutton.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/models/users.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/pages/login.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
//--- Generating textfield controllers
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

//---Generating a file to locally store images, profile pictures
//---Generating a string to hold the image string = photoPath
//---Generating a user's instance

  File? _imageFile;
  String? _photoPath;
  AppUser? _user;

//Generating a picker to pick images from both gallery and camera

  final _picker = ImagePicker();

//---Generating an instance of the database

  final DatabaseManager _databaseManager = DatabaseManager();

//--Checking is the user is logged in with a boolean

  bool _isLoading = false;

//---Initialising state

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

//---Disposing of the controllers after they held a value

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

//checking the state of the profile in the data
//si le profile existe, it gets loaded with the recently saved data
//en initializing la base de données

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      await _databaseManager.initialisation();
    } catch (_) {}

//Getting an instance of the app user in the database
//using the function getUserByEmail
//to be sure to display les information correspondante au user
//that we need to
//and if we do not get any user on doit rien display
//pas d'information

    AppUser? user;
    try {
      user = await _databaseManager.getUserByEmail(widget.email);
    } catch (_) {
      try {
        user = await _databaseManager.getUserByEmail(widget.email);
      } catch (_) {
        user = null;
      }
    }

    if (!mounted) return;

    if (user != null) {
      //Lorsqu'on retrouve un user dans la database
      //we display all data related to him
      //coming from the controllers

      if ((user.fname ?? '').isNotEmpty) {
        _fnameController.text = user.fname!;
      }
      if ((user.lname ?? '').isNotEmpty) {
        _lnameController.text = user.lname!;
      }

      //Pour l'email on display celui qui est dans la database
      //ou alors ce qu'on receuill du Sign up

      if ((user.email ?? '').isNotEmpty) {
        _emailController.text = user.email;
      } else if (_emailController.text.isEmpty) {
        _emailController.text = widget.email;
      }
      if ((user.phone ?? '').isNotEmpty) {
        _phoneController.text = user.phone;
      }

      // Set the image only if we have its path dans le file
      //sinon si c'est empty on display le default avatar

      if (user.photoPath != null && user.photoPath!.isNotEmpty) {
        final f = File(user.photoPath!);
        if (f.existsSync()) {
          _imageFile = f;
          _photoPath = user.photoPath;
        }
      }

      _user = user;
    } else {
      //If there is no user found dans la database don't clear the UI.
      //but ensure email field has widget.email
      //so nothing remains empty

      if (_emailController.text.isEmpty && widget.email.isNotEmpty) {
        _emailController.text = widget.email;
      }
    }

    //if the profile loads successfully
    //le statut de isLoading devient faux parce qu'on a succeed
    //to display the loaded user

    setState(() => _isLoading = false);
  }

//----Generating the pick image function
//---Picking the image from a source and setting it's quality to 70

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _photoPath = picked.path;
        });

//Si le user is not null then on generate an instance de user
//to whom you assign profile path that was just picked
//and then on maj la database with the new path set
//so when coming back we get the last set image
//according to the info store in the db

        if (_user != null) {
          final updated = AppUser(
            id: _user!.id,
            fname: _user!.fname,
            lname: _user!.lname,
            email: _user!.email,
            password: _user!.password,
            phone: _user!.phone,
            photoPath: _photoPath ?? '',
          );
          await _databaseManager.updateAppUser(updated);
          _user = updated;
        }
      }
    } catch (e) {
      //debugprint is a function that send a message in the console
      //to print the error so we have an idea of what the error is
      //aslo send a snackbar that displays the error for the user to know

      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  //picker options helps us pick images from two sources
  //when the camera icon is clicked on
  //Gallery or camera

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.photo_camera_solid),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  //when the profile is updated with new info
  //they are store and if it's empty, the "no user message"
  //gets displayed

  Future<void> _updateProfile() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user loaded to update')),
      );
      return;
    }

//again generating an appuser instance
//pour sauver les data du user dans la database
//en utilisant la method updateAppUser

    final updated = AppUser(
      id: _user!.id,
      fname: _fnameController.text.trim(),
      lname: _lnameController.text.trim(),
      email: _emailController.text.trim(),
      password: _user!.password,
      phone: _phoneController.text.trim(),
      photoPath: _photoPath ?? '',
    );

    try {
      await _databaseManager.updateAppUser(updated);

      //loading profile with updates or error message if they failed
      //for some reason

      await _loadProfile();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Your changes have been saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  //this function cancels the changes the user might have wanted
  //to make to their profile
  //if the var doCancel is true you simply load the profile info
  //that was lastly saved

  Future<void> _confirmCancel() async {
    final doCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Are you sure you want to discard your edits?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'No',
              )),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Yes',
              )),
        ],
      ),
    );

//doCancel acts here

    if (doCancel == true) {
      await _loadProfile();
    }
  }

  //Showing full image when the user clicks on the image
  //to make it bigger , you simply have to "not" the _imageFile

  void _showFullImage() {
    if (_imageFile == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.file(_imageFile!),
        ),
      ),
    );
  }

  //Generating the logout function
  //that replaces the current page with the LoginPage
  //meaning on revient vers le login by replacing it
  //avec la page actuelle

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('P R O F I L E',
            style: TextStyle(color: Color(0xff050c20))),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.power, color: Color(0xff050c20)),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff050c20)))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showFullImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,

                            //displaying a white person icon
                            //when the imageFile is empty
                            //donc quand y'a pas d'image stored yet
                            //genre new account for example

                            child: _imageFile == null
                                ? const Icon(
                                    CupertinoIcons.person_crop_circle_fill,
                                    size: 80,
                                    color: Colors.white)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(CupertinoIcons.camera_fill,
                                  color: Color(0xff050c20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Mytextfield(
                      controller: _fnameController,
                      hintText: 'First Name',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.person_fill),
                    ),
                    const SizedBox(height: 20),
                    Mytextfield(
                      controller: _lnameController,
                      hintText: 'Last Name',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.person_fill),
                    ),
                    const SizedBox(height: 20),
                    Mytextfield(
                      controller: _emailController,
                      hintText: 'Email',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.mail_solid),
                    ),
                    const SizedBox(height: 20),
                    Mytextfield(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.phone_fill),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          10,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MyButton(
                          textbutton: 'Update',
                          onTap: _updateProfile,
                          buttonHeight: 40,
                          buttonWidth: 100,
                        ),
                        const SizedBox(width: 40),
                        MyButton(
                          textbutton: 'Cancel',
                          onTap: _confirmCancel,
                          buttonHeight: 40,
                          buttonWidth: 100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: MyNavBar(currentIndex: 3, email: widget.email),
    );
  }
}
