import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OTPService {
  final _storage = const FlutterSecureStorage();
  final Duration _otpValidity = const Duration(minutes: 5);
  
  // Generate a random OTP
  String _generateOTP() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  // Store OTP with expiry time
  Future<void> _storeOTP(String email, String otp) async {
    final expiryTime = DateTime.now().add(_otpValidity).toIso8601String();
    await _storage.write(key: 'otp_$email', value: otp);
    await _storage.write(key: 'otp_expiry_$email', value: expiryTime);
  }

  // Send OTP via email using Gmail
  Future<bool> sendOTP(String email) async {
    try {
      final otp = _generateOTP();
      await _storeOTP(email, otp);
      
      // Send mail function
      await _sendMail(
        [email],
        'Your OTP Code',
      );
      
      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }
  
  // Send mail function
  Future<void> _sendMail(
    List<String> recipientEmails,
    String mailSubject,
  ) async {
    String username = 'smartblooddonor.app@gmail.com';
    String password = 'hlbapibcpbmcravh'; // App Password
    
    final smtpServer = gmail(username, password);
    
    final message = Message()
      ..from = Address(username, 'Blood Donor Service')
      ..recipients.addAll(recipientEmails)
      ..subject = mailSubject
      ..text = 'Your OTP code is: ${await _storage.read(key: 'otp_${recipientEmails[0]}')}.\nThis code will expire in 5 minutes.';
      
    try {
      await send(message, smtpServer);
      print('Email sent successfully!');
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final storedOTP = await _storage.read(key: 'otp_$email');
      final expiryTimeStr = await _storage.read(key: 'otp_expiry_$email');
      
      if (storedOTP == null || expiryTimeStr == null) {
        return false;
      }
      
      final expiryTime = DateTime.parse(expiryTimeStr);
      final now = DateTime.now();
      
      if (now.isAfter(expiryTime)) {
        // OTP has expired
        await clearOTP(email);
        return false;
      }
      
      return storedOTP == otp;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Clear OTP data
  Future<void> clearOTP(String email) async {
    await _storage.delete(key: 'otp_$email');
    await _storage.delete(key: 'otp_expiry_$email');
  }
} 