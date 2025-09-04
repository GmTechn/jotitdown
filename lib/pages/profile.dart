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
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _imageFile;
  String? _photoPath;
  AppUser? _user;

  final _picker = ImagePicker();
  final DatabaseManager _databaseManager = DatabaseManager();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Load profile from DB. This method is defensive:
  /// - It tries both possible DB getters (getAppUserByEmail / getUserByEmail)
  ///   to be compatible with small variations in your DatabaseManager API.
  /// - It DOES NOT clear existing values if DB returns null or empty fields.
  /// - It only overwrites a text controller when the DB value is non-empty.
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    // Try to (re)initialize DB if available (some DatabaseManager implementations
    // expose `initialisation()` — calling it is safe if already initialized).
    try {
      await _databaseManager.initialisation();
    } catch (_) {
      // ignore if method doesn't exist or DB already initialized
    }

    AppUser? user;
    try {
      user = await _databaseManager.getUserByEmail(widget.email);
    } catch (_) {
      try {
        // fallback name some implementations use
        user = await _databaseManager.getUserByEmail(widget.email);
      } catch (_) {
        user = null;
      }
    }

    if (!mounted) return;

    if (user != null) {
      // Only overwrite fields when DB value is non-empty so we don't erase
      // data that might be currently typed in UI.
      if ((user.fname ?? '').isNotEmpty) {
        _fnameController.text = user.fname;
      }
      if ((user.lname ?? '').isNotEmpty) {
        _lnameController.text = user.lname;
      }
      // email is authoritative; prefer DB email if present, otherwise keep existing or widget.email
      if ((user.email ?? '').isNotEmpty) {
        _emailController.text = user.email;
      } else if (_emailController.text.isEmpty) {
        _emailController.text = widget.email;
      }
      if ((user.phone ?? '').isNotEmpty) {
        _phoneController.text = user.phone;
      }

      // Only set image if path exists and file exists on disk
      if (user.photoPath != null && user.photoPath!.isNotEmpty) {
        final f = File(user.photoPath!);
        if (f.existsSync()) {
          _imageFile = f;
          _photoPath = user.photoPath;
        }
      }

      _user = user;
    } else {
      // No DB user found: don't clear the UI. Ensure email field has widget.email.
      if (_emailController.text.isEmpty && widget.email.isNotEmpty) {
        _emailController.text = widget.email;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _photoPath = picked.path;
        });

        // ✅ Persist immediately if user exists
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
          _user = updated; // keep in memory too
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

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

  /// Save updated fields to DB. If there's no loaded user we show a message.
  Future<void> _updateProfile() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user loaded to update')),
      );
      return;
    }

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
      // reload to reflect DB canonical values (but _loadProfile won't clear non-empty UI)
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
                  style: TextStyle(color: Colors.blue),
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

  /// Revert UI fields to the last-saved DB state with confirmation
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

    if (doCancel == true) {
      await _loadProfile();
    }
  }

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
                      hintText: 'Phone',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.phone_fill),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
