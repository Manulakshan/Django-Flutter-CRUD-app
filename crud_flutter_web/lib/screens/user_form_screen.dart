import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/input_field.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({Key? key, this.user}) : super(key: key);

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  html.File? _pickedImage;
  String? _previewImageUrl;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.user != null;
    if (_isEditMode) {
      _populateForm(widget.user!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    if (_previewImageUrl != null) {
      html.Url.revokeObjectUrl(_previewImageUrl!);
    }
    super.dispose();
  }

  void _populateForm(User user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _addressController.text = user.address ?? '';
    _ageController.text = user.age?.toString() ?? '';
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      _previewImageUrl = user.profilePicture;
    }
  }

  Future<void> _pickImage() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _pickedImage = files.first;
          if (_previewImageUrl != null) {
            html.Url.revokeObjectUrl(_previewImageUrl!);
          }
          _previewImageUrl = html.Url.createObjectUrlFromBlob(_pickedImage!);
        });
      }
    });
  }

  Future<bool> _isEmailUnique(String email, {int? excludeUserId}) async {
    try {
      final response = await ApiService.getUsers();
      final allUsers = List<User>.from(response['users']);
      return !allUsers.any((user) => 
          user.email.toLowerCase() == email.toLowerCase() && 
          (excludeUserId == null || user.id != excludeUserId));
    } catch (e) {
      print('Error checking email uniqueness: $e');
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = User(
      id: _isEditMode ? widget.user!.id : null,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      age: _ageController.text.trim().isEmpty ? null : int.tryParse(_ageController.text.trim()),
    );

    try {
      // Check email uniqueness
      final isUnique = await _isEmailUnique(
        user.email,
        excludeUserId: _isEditMode ? user.id : null,
      );

      if (!isUnique) {
        Fluttertoast.showToast(msg: 'A user with this email already exists');
        return;
      }

      if (_isEditMode) {
        final fields = <String, dynamic>{
          'name': user.name,
          'email': user.email,
          if (user.phoneNumber != null) 'phone_number': user.phoneNumber,
          if (user.address != null) 'address': user.address,
          if (user.age != null) 'age': user.age,
        };

        if (_pickedImage != null) {
          await ApiService.patchUserWithImage(user.id!, fields, _pickedImage!);
        } else {
          await ApiService.patchUser(user.id!, fields);
        }
        Fluttertoast.showToast(msg: 'User updated successfully');
      } else {
        if (_pickedImage != null) {
          await ApiService.createUserWithImage(user, _pickedImage!);
        } else {
          await ApiService.createUser(user);
        }
        Fluttertoast.showToast(msg: 'User created successfully');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit User' : 'Add New User'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _previewImageUrl != null
                                  ? NetworkImage(_previewImageUrl!)
                                  : null,
                              child: _previewImageUrl == null
                                  ? Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    InputField(
                      controller: _nameController,
                      label: 'Name',
                      icon: Icons.person,
                      validator: (value) =>
                          value?.trim().isEmpty ?? true ? 'Name is required' : null,
                    ),
                    SizedBox(height: 16),
                    InputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Email is required';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value!)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    InputField(
                      controller: _phoneController,
                      label: 'Phone (Optional)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isNotEmpty ?? false) {
                          final phoneRegex = RegExp(r'^[0-9+\-\s()]*$');
                          if (!phoneRegex.hasMatch(value!)) {
                            return 'Enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    InputField(
                      controller: _addressController,
                      label: 'Address (Optional)',
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    InputField(
                      controller: _ageController,
                      label: 'Age (Optional)',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isNotEmpty ?? false) {
                          final age = int.tryParse(value!);
                          if (age == null) {
                            return 'Enter a valid number';
                          }
                          if (age < 1 || age > 120) {
                            return 'Age must be between 1 and 120';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(_isEditMode ? 'Update User' : 'Create User'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
