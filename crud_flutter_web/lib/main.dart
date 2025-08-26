import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'models/user.dart';
import 'services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innobot User Management App',
      debugShowCheckedModeBanner: false,
      home: UserPage(),
    );
  }
}

class UserPage extends StatefulWidget {
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  // controllers
  final TextEditingController nameCtl = TextEditingController();
  final TextEditingController emailCtl = TextEditingController();
  final TextEditingController phoneCtl = TextEditingController();
  final TextEditingController addressCtl = TextEditingController();
  final TextEditingController ageCtl = TextEditingController();

  List<User> users = [];
  bool loading = false;
  bool showForm = false;

  // Pagination
  int currentPage = 1;
  final int pageSize = 5;
  int totalUsers = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;

  // Edit state
  int? editUserId;
  html.File? pickedImage;
  String? previewObjectUrl; 

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    phoneCtl.dispose();
    addressCtl.dispose();
    ageCtl.dispose();
    if (previewObjectUrl != null) html.Url.revokeObjectUrl(previewObjectUrl!);
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.getUsers(
        page: currentPage,
        pageSize: pageSize,
      );
      
      setState(() {
        users = List<User>.from(response['users']);
        totalUsers = response['count'];
        hasNextPage = response['next'];
        hasPreviousPage = response['previous'];
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching users: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void nextPage() {
    if (hasNextPage) {
      setState(() => currentPage++);
      fetchUsers();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchUsers();
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final name = nameCtl.text.trim();
    final email = emailCtl.text.trim();
    final phone = phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim();
    final address =
        addressCtl.text.trim().isEmpty ? null : addressCtl.text.trim();
    final age =
        ageCtl.text.trim().isEmpty ? null : int.tryParse(ageCtl.text.trim());

    final user = User(
      id: editUserId,
      name: name,
      email: email,
      phoneNumber: phone,
      address: address,
      age: age,
    );

    try {
      if (editUserId == null) {
        final isUnique = await isEmailUnique(email);
        if (!isUnique) {
          _scaffoldKey.currentState?.showSnackBar(
            const SnackBar(content: Text('A user with this email already exists')),
          );
          setState(() => loading = false);
          return;
        }

        if (pickedImage != null) {
          await ApiService.createUserWithImage(user, pickedImage!);
        } else {
          await ApiService.createUser(user);
        }
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(content: Text('User created successfully')),
        );
      } else {
        final isUnique =
            await isEmailUnique(email, excludeUserId: editUserId);
        if (!isUnique) {
          _scaffoldKey.currentState?.showSnackBar(
            const SnackBar(
                content: Text('Another user with this email already exists')),
          );
          setState(() => loading = false);
          return;
        }

        final fields = <String, dynamic>{
          'name': name,
          'email': email,
          if (phone != null) 'phone_number': phone,
          if (address != null) 'address': address,
          if (age != null) 'age': age,
        };

        if (pickedImage != null) {
          await ApiService.patchUserWithImage(editUserId!, fields, pickedImage!);
        } else {
          await ApiService.patchUser(editUserId!, fields);
        }
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(content: Text('User updated successfully')),
        );
      }

      clearForm();
      await fetchUsers();
      setState(() => showForm = false);
    } catch (e) {
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void clearForm() {
    editUserId = null;
    nameCtl.clear();
    emailCtl.clear();
    phoneCtl.clear();
    addressCtl.clear();
    ageCtl.clear();
    if (previewObjectUrl != null) {
      html.Url.revokeObjectUrl(previewObjectUrl!);
      previewObjectUrl = null;
    }
    pickedImage = null;
    setState(() {});
  }

  void startEdit(User u) {
    editUserId = u.id;
    nameCtl.text = u.name;
    emailCtl.text = u.email;
    phoneCtl.text = u.phoneNumber ?? '';
    addressCtl.text = u.address ?? '';
    ageCtl.text = u.age?.toString() ?? '';

    if (previewObjectUrl != null) {
      html.Url.revokeObjectUrl(previewObjectUrl!);
      previewObjectUrl = null;
    }

    if (u.profilePicture != null && u.profilePicture!.isNotEmpty) {
      previewObjectUrl = u.profilePicture;
    }

    pickedImage = null;

    setState(() {});
  }

  Future<void> doDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete?'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteUser(id);
        Fluttertoast.showToast(msg: 'Deleted');
        await fetchUsers();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Delete error: $e');
      }
    }
  }

  // responsive user list
  Widget _buildUserList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: users.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No users found'),
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Profile')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Age')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: users.map((user) {
                        return DataRow(cells: [
                          DataCell(
                            user.profilePicture != null &&
                                    user.profilePicture!.isNotEmpty
                                ? CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        NetworkImage(user.profilePicture!),
                                  )
                                : CircleAvatar(
                                    radius: 20,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ),
                          DataCell(Text(user.name)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.phoneNumber ?? 'N/A')),
                          DataCell(Text(user.age?.toString() ?? 'N/A')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  startEdit(user);
                                  setState(() => showForm = true);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => doDelete(user.id!),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
        );
      },
    );
  }

  // user form
  Widget _buildUserForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: previewObjectUrl != null
                        ? NetworkImage(previewObjectUrl!)
                        : null,
                    child: previewObjectUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: nameCtl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: validateName,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: emailCtl,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: phoneCtl,
              decoration: InputDecoration(
                labelText: 'Phone (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: validatePhone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: addressCtl,
              decoration: InputDecoration(
                labelText: 'Address (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: ageCtl,
              decoration: InputDecoration(
                labelText: 'Age (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                hintText: 'Must be a number between 1-120',
              ),
              keyboardType: TextInputType.number,
              validator: validateAge,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => showForm = false),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Back to List'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: save,
                  icon: Icon(Icons.save),
                  label: Text(editUserId == null ? 'Create User' : 'Update User'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Image picker method
  void pickImage() {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          pickedImage = files.first;
          if (previewObjectUrl != null) {
            html.Url.revokeObjectUrl(previewObjectUrl!);
          }
          previewObjectUrl = html.Url.createObjectUrlFromBlob(pickedImage!);
        });
      }
    });
  }

  // Validation methods
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]*$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Age is optional
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Enter a valid number';
    }
    if (age < 1 || age > 120) {
      return 'Age must be between 1 and 120';
    }
    return null;
  }

  // Email uniqueness check
  Future<bool> isEmailUnique(String email, {int? excludeUserId}) async {
    try {
      // First, check the current page
      for (final user in users) {
        if (user.email.toLowerCase() == email.toLowerCase() &&
            (excludeUserId == null || user.id != excludeUserId)) {
          return false;
        }
      }
      
      // If not found on current page, check if we need to check other pages
      if (hasNextPage) {
        // For simplicity, we'll just check the next page
        // In a real app, you might want to implement a more thorough check
        final nextPage = currentPage + 1;
        final response = await ApiService.getUsers(page: nextPage, pageSize: pageSize);
        final nextPageUsers = List<User>.from(response['users']);
        
        return !nextPageUsers.any((user) =>
            user.email.toLowerCase() == email.toLowerCase() &&
            (excludeUserId == null || user.id != excludeUserId));
      }
      
      return true;
    } catch (e) {
      print('Error checking email uniqueness: $e');
      return false; // Default to false to prevent duplicate emails on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('User Management'),
        actions: [
          if (!showForm)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  clearForm();
                  setState(() => showForm = true);
                },
                icon: Icon(Icons.add),
                label: Text('Add User'),
              ),
            ),
          if (showForm)
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => setState(() => showForm = false),
              tooltip: 'Back to List',
            ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          child: loading
              ? Center(child: CircularProgressIndicator())
              : showForm
                  ? _buildUserForm()
                  : Column(
                      children: [
                        _buildUserList(),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: previousPage,
                              child: Text('Previous'),
                            ),
                            SizedBox(width: 16),
                            Text('Page $currentPage of $totalUsers'),
                            SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: nextPage,
                              child: Text('Next'),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
