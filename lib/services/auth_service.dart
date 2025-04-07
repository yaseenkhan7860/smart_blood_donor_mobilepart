import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:testapp/models/user.dart';
import 'package:testapp/services/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _storage = const FlutterSecureStorage();

  // Admin credentials
  static const String _adminId = 'admin';
  static const String _adminPassword = '12345';

  // List of allowed Gmail domains
  final List<String> _allowedDomains = [
    'gmail.com',
    // Add more allowed domains if needed
  ];

  bool _isValidGmail(String email) {
    // Check if email ends with allowed domain
    return _allowedDomains.any((domain) => email.toLowerCase().endsWith('@$domain'));
  }

  Future<bool> register(String email, String password, String name, String? bloodGroup) async {
    try {
      // Validate input
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (name.isEmpty) {
        throw Exception('Name cannot be empty');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }
      if (!email.contains('@')) {
        throw Exception('Please enter a valid email address');
      }
      if (!_isValidGmail(email)) {
        throw Exception('Only Gmail addresses are allowed');
      }

      // Check if user already exists by email
      final existingUserByEmail = await _dbHelper.getUserByEmail(email);
      
      if (existingUserByEmail != null) {
        throw Exception('Email already exists. Please use a different email.');
      }

      // Create new user
      final user = {
        'email': email,
        'password': password,
        'name': name,
        'bloodGroup': bloodGroup,
        'token': 'dummy_token_${DateTime.now().millisecondsSinceEpoch}',
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        await _dbHelper.insertUser(user);
        await _storage.write(key: 'token', value: user['token']);
        await _storage.write(key: 'isAdmin', value: 'false');
        await _storage.write(key: 'user_email', value: email);
        return true;
      } catch (e) {
        print('Database error: $e');
        throw Exception('Failed to create user account. Please try again.');
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<bool> login(String identifier, String password) async {
    try {
      // Check for admin login
      if (identifier == _adminId) {
        if (password == _adminPassword) {
          await _storage.write(key: 'token', value: 'admin_token');
          await _storage.write(key: 'isAdmin', value: 'true');
          await _storage.write(key: 'user_email', value: identifier);
          return true;
        }
        return false;
      }

      // For non-admin, validate Gmail domain
      if (!_isValidGmail(identifier)) {
        throw Exception('Only Gmail addresses are allowed for user login');
      }

      // Try to find user by email
      final user = await _dbHelper.getUserByIdentifier(identifier);
      
      if (user == null || user['password'] != password) {
        return false;
      }

      await _storage.write(key: 'token', value: user['token']);
      await _storage.write(key: 'isAdmin', value: 'false');
      await _storage.write(key: 'user_email', value: user['email']);
      
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'isAdmin');
      await _storage.delete(key: 'user_email');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'token');
      return token != null;
    } catch (e) {
      print('Login check error: $e');
      return false;
    }
  }

  Future<bool> isAdmin() async {
    try {
      final username = await _storage.read(key: 'username');
      // Only the literal 'admin' username should be considered an admin
      return username == 'admin';
    } catch (e) {
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final email = await _storage.read(key: 'user_email');
      
      if (email == null) return null;
      
      // If admin, return admin user
      if (email == _adminId) {
        return User(
          id: 'admin',
          email: _adminId,
          name: 'Admin',
          bloodGroup: null,
        );
      }
      
      final userData = await _dbHelper.getUserByEmail(email);
      if (userData == null) return null;
      
      return User(
        id: userData['id'].toString(),
        email: userData['email'],
        name: userData['name'],
        bloodGroup: userData['bloodGroup'],
      );
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
} 