import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'user_form_screen.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> users = [];
  bool loading = false;
  int currentPage = 1;
  final int pageSize = 10;
  int totalUsers = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  
  // Sorting
  String _sortColumn = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
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
      
      // Apply sorting after fetching
      _sortUsers();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching users: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _sortUsers() {
    users.sort((a, b) {
      int compareResult;
      switch (_sortColumn) {
        case 'name':
          compareResult = a.name.compareTo(b.name);
          break;
        case 'email':
          compareResult = a.email.compareTo(b.email);
          break;
        case 'age':
          compareResult = (a.age ?? 0).compareTo(b.age ?? 0);
          break;
        default:
          compareResult = 0;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
  }

  void _onSort(String columnName) {
    if (_sortColumn == columnName) {
      setState(() {
        _sortAscending = !_sortAscending;
      });
    } else {
      setState(() {
        _sortColumn = columnName;
        _sortAscending = true;
      });
    }
    _sortUsers();
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

  Future<void> _navigateToUserForm(BuildContext context, [User? user]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(user: user),
      ),
    );

    if (result == true) {
      await fetchUsers();
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteUser(id);
        Fluttertoast.showToast(msg: 'User deleted successfully');
        await fetchUsers();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error deleting user: $e');
      }
    }
  }

  Widget _buildUserTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _getSortColumnIndex(),
        sortAscending: _sortAscending,
        columns: [
          DataColumn(
            label: Text('Profile'),
          ),
          DataColumn(
            label: Text('Name'),
            onSort: (_, __) => _onSort('name'),
          ),
          DataColumn(
            label: Text('Email'),
            onSort: (_, __) => _onSort('email'),
          ),
          DataColumn(
            label: Text('Phone'),
          ),
          DataColumn(
            label: Text('Age'),
            numeric: true,
            onSort: (_, __) => _onSort('age'),
          ),
          DataColumn(
            label: Text('Actions'),
          ),
        ],
        rows: users.map((user) {
          return DataRow(
            cells: [
              DataCell(
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                      ? NetworkImage(user.profilePicture!)
                      : null,
                  child: user.profilePicture == null || user.profilePicture!.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : null,
                ),
              ),
              DataCell(Text(user.name)),
              DataCell(
                Tooltip(
                  message: user.email,
                  child: Text(
                    user.email,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              DataCell(Text(user.phoneNumber ?? '-')),
              DataCell(Text(user.age?.toString() ?? '-')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToUserForm(context, user),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user.id!),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  int? _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'name':
        return 1;
      case 'email':
        return 2;
      case 'age':
        return 4;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToUserForm(context),
              icon: Icon(Icons.add),
              label: Text('Add User'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No users found'),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildUserTable(),
                      ),
          ),
          if (users.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                border: Border(
                  top: BorderSide(color: Theme.of(context).primaryColor), 
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${(currentPage - 1) * pageSize + 1}-${(currentPage - 1) * pageSize + users.length} of $totalUsers users',
                    style: TextStyle(color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 18,color: Colors.white),
                        onPressed: hasPreviousPage ? previousPage : null,
                        tooltip: 'Previous Page',
                      ),
                      Text('Page $currentPage of ${(totalUsers / pageSize).ceil()}', style: TextStyle(color: Colors.white)),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
                        onPressed: hasNextPage ? nextPage : null,
                        tooltip: 'Next Page',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
