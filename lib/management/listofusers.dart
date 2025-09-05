import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mytextfield.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/models/users.dart';

class ListOfUsers extends StatefulWidget {
  const ListOfUsers({super.key});

  @override
  State<ListOfUsers> createState() => _ListOfUsersState();
}

class _ListOfUsersState extends State<ListOfUsers> {
  final TextEditingController searchController = TextEditingController();

  // Users list
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];

  final DatabaseManager _databaseManager = DatabaseManager();

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    await _databaseManager.initialisation();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _databaseManager.getAllAppUsers();
    setState(() {
      _users = users.cast<AppUser>();
      _filteredUsers = users.cast<AppUser>();
    });
  }

  // Search
  void _searchUsers(String query) {
    final results = _users.where((user) {
      final fullName = '${user.fname} ${user.lname}'.toLowerCase();
      final email = (user.email ?? '').toLowerCase();
      return fullName.contains(query.toLowerCase()) ||
          email.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredUsers = results;
    });
  }

  // Delete user
  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete this user?"),
        content: Text("Are you sure you want to delete ${user.fname}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
            ),
          ),
        ],
      ),
    );

    if (confirm == true && user.id != null) {
      await _databaseManager.deleteAppUser(user.id!);
      _loadUsers();
    }
  }

  // Edit user
  Future<void> _editUser(AppUser user) async {
    final newFname = TextEditingController(text: user.fname);
    final newLname = TextEditingController(text: user.lname);
    final newEmail = TextEditingController(text: user.email);
    final newPassword = TextEditingController(text: user.password);
    final newPhone = TextEditingController(text: user.phone);

    await showDialog(
      context: context,
      builder: (context) {
        bool isPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit user info'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Mytextfield(
                      controller: newFname,
                      hintText: 'First Name',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.person_fill)),
                  const SizedBox(height: 10),
                  Mytextfield(
                      controller: newLname,
                      hintText: 'Last Name',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.person_fill)),
                  const SizedBox(height: 10),
                  Mytextfield(
                      controller: newEmail,
                      hintText: 'Email',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.mail_solid)),
                  const SizedBox(height: 10),
                  Mytextfield(
                    controller: newPassword,
                    hintText: 'Password',
                    obscureText: !isPasswordVisible,
                    leadingIcon:
                        const Icon(Icons.lock, color: Color(0xff050c20)),
                    trailingIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xff050c20),
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Mytextfield(
                      controller: newPhone,
                      hintText: 'Phone Number',
                      obscureText: false,
                      leadingIcon: const Icon(CupertinoIcons.phone_fill)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final updatedUser = AppUser(
                    id: user.id,
                    fname: newFname.text,
                    lname: newLname.text,
                    email: newEmail.text,
                    password: newPassword.text,
                    phone: newPhone.text,
                    photoPath: user.photoPath,
                  );

                  await _databaseManager.updateAppUser(updatedUser as AppUser);

                  Navigator.pop(context);
                  _loadUsers();
                },
                child: const Text(
                  'Save',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Users',
            style: TextStyle(color: Color(0xff050c20))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              cursorColor: const Color(0xff050c20),
              controller: searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                focusedBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xff050c20), width: 1.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xff050c20)),
                hintText: "Search users...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xff050c20))),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListTile(
                      title: Text('${user.fname} ${user.lname}'),
                      subtitle: Text(user.email ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () => _deleteUser(user),
                              icon: const Icon(
                                CupertinoIcons.delete_solid,
                                color: Color(0xff050c20),
                              )),
                          IconButton(
                              onPressed: () => _editUser(user),
                              icon: const Icon(
                                CupertinoIcons.pencil,
                                color: Color(0xff050c20),
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
