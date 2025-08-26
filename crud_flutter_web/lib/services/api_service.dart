import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';

class ApiService {
  // Get base URL from environment variables
  static String get baseUrl => dotenv.get('API_URL', fallback: 'http://127.0.0.1:8000/api/users/');

  // Get users with pagination support
  static Future<Map<String, dynamic>> getUsers({int page = 1, int pageSize = 5}) async {
    final url = Uri.parse('$baseUrl?page=$page&page_size=$pageSize');
    print('Fetching users from: $url');
    final res = await http.get(url);
    
    print('Response status: ${res.statusCode}');
    
    if (res.statusCode == 200) {
      try {
        final body = json.decode(res.body);
        print('Parsed response: $body');
        
        List<dynamic> usersData = [];
        
        // Handle direct list response
        if (body is List) {
          usersData = body;
          
          // Client-side pagination
          final startIndex = (page - 1) * pageSize;
          final endIndex = startIndex + pageSize;
          usersData = startIndex < usersData.length 
              ? usersData.sublist(
                  startIndex,
                  endIndex < usersData.length ? endIndex : usersData.length)
              : [];
              
          return {
            'users': usersData.map((e) => User.fromJson(e)).toList(),
            'count': body.length,
            'next': endIndex < body.length,
            'previous': page > 1,
          };
        } 
        // Handle other response formats if needed
        else if (body is Map) {
          usersData = body['results'] ?? body['data'] ?? [];
          
          return {
            'users': usersData.map((e) => User.fromJson(e)).toList(),
            'count': body['count'] ?? usersData.length,
            'next': body['next'] != null,
            'previous': body['previous'] != null,
          };
        }
        
        // Default empty response
        return {
          'users': [],
          'count': 0,
          'next': false,
          'previous': false,
        };
        
      } catch (e) {
        print('Error parsing response: $e');
        rethrow;
      }
    } else {
      throw Exception('Failed to load users: ${res.statusCode}');
    }
  }

  // Create user without file (JSON)
  static Future<User> createUser(User user) async {
    final res = await http.post(Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(user.toJson()));
    if (res.statusCode == 201 || res.statusCode == 200) {
      return User.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed creating user: ${res.statusCode} ${res.body}');
    }
  }

  // Create user WITH image (web) using FormData + HttpRequest
  static Future<User> createUserWithImage(User user, html.File image) async {
    final form = html.FormData();
    form.append('name', user.name);
    form.append('email', user.email);
    if (user.phoneNumber != null) form.append('phone_number', user.phoneNumber!);
    if (user.address != null) form.append('address', user.address!);
    if (user.age != null) form.append('age', '${user.age}');
    form.appendBlob('profile_picture', image, image.name);

    final request = await html.HttpRequest.request(
      baseUrl,
      method: 'POST',
      sendData: form,
      // do NOT set Content-Type header; browser will set boundary automatically
    );

    if (request.status == 201 || request.status == 200) {
      return User.fromJson(jsonDecode(request.responseText!));
    } else {
      throw Exception('Failed creating user (multipart): ${request.status} ${request.responseText}');
    }
  }

  // Patch update without file (partial update)
  static Future<User> patchUser(int id, Map<String, dynamic> patchData) async {
    final res = await http.patch(Uri.parse("$baseUrl$id/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(patchData));
    if (res.statusCode == 200) {
      return User.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed patching user: ${res.statusCode} ${res.body}');
    }
  }

  // Update with image (multipart) - uses PATCH with FormData
  static Future<User> patchUserWithImage(int id, Map<String, dynamic> fields, html.File image) async {
    final form = html.FormData();
    fields.forEach((k, v) {
      if (v != null) form.append(k, v.toString());
    });
    form.appendBlob('profile_picture', image, image.name);

    final request = await html.HttpRequest.request(
      "$baseUrl$id/",
      method: 'PATCH',
      sendData: form,
    );

    if (request.status == 200) {
      return User.fromJson(jsonDecode(request.responseText!));
    } else {
      throw Exception('Failed patching (multipart): ${request.status} ${request.responseText}');
    }
  }

  // Delete
  static Future<void> deleteUser(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl$id/"));
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed deleting user: ${res.statusCode} ${res.body}');
    }
  }

  // Helper to build full image URL (in case backend returns a relative path)
  static String? fullImageUrl(String? profilePicture) {
    if (profilePicture == null) return null;
    if (profilePicture.startsWith('http')) return profilePicture;
    // Ensure it has leading slash
    final p = profilePicture.startsWith('/') ? profilePicture : '/$profilePicture';
    final base = dotenv.get('API_URL', fallback: 'http://127.0.0.1:8000');
    return '$base$p';
  }
}
