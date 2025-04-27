import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BloodRequest {
  final String id;
  final String bloodType;
  final String patientName;
  final String hospital;
  final String urgency;
  final DateTime createdAt;
  final String? contactPhone;
  final int? unitsNeeded;
  final String? notes;

  BloodRequest({
    required this.id,
    required this.bloodType,
    required this.patientName,
    required this.hospital,
    required this.urgency,
    required this.createdAt,
    this.contactPhone,
    this.unitsNeeded,
    this.notes,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'],
      bloodType: json['bloodType'],
      patientName: json['patientName'],
      hospital: json['hospital'],
      urgency: json['urgency'] ?? 'standard',
      createdAt: DateTime.parse(json['createdAt']),
      contactPhone: json['contactPhone'],
      unitsNeeded: json['unitsNeeded'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bloodType': bloodType,
      'patientName': patientName,
      'hospital': hospital,
      'urgency': urgency,
      'createdAt': createdAt.toIso8601String(),
      'contactPhone': contactPhone,
      'unitsNeeded': unitsNeeded,
      'notes': notes,
    };
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final _storage = const FlutterSecureStorage();
  late final SupabaseClient _supabaseClient;
  final _notificationsStreamController =
      StreamController<List<NotificationModel>>.broadcast();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  RealtimeChannel? _channel;

  // Stream that will emit notifications when they arrive
  Stream<List<NotificationModel>> get notificationsStream =>
      _notificationsStreamController.stream;

  // Singleton pattern
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Get Supabase credentials from secure storage
    final supabaseUrl = await SupabaseConfig.getSupabaseUrl();
    final supabaseAnonKey = await SupabaseConfig.getSupabaseAnonKey();

    if (supabaseUrl == null || supabaseAnonKey == null) {
      debugPrint('Supabase not configured. Notifications will not work.');
      _notificationsStreamController.add([]);
      return;
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _supabaseClient = Supabase.instance.client;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Set up real-time subscription
    _subscribeToNotifications();
    _subscribeToBloodRequests();

    // Load initial notifications
    await fetchNotifications();
  }

  void _subscribeToNotifications() {
    // Subscribe to notifications table changes
    _supabaseClient
        .from('notifications')
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        // Process each new notification
        for (final notificationData in data) {
          _handleNewNotification({'new': notificationData});
        }
      }
    });
  }

  void _handleNewNotification(dynamic payload) async {
    // Get user info to check if notification is for this user
    final currentEmail = await _storage.read(key: 'user_email');
    if (currentEmail == null) return;

    // Parse the notification data
    final notificationData = payload['new'];
    final recipients = notificationData['recipients'] as List<dynamic>?;

    // Check if this notification is for all users or specifically for this user
    if (recipients == null ||
        recipients.isEmpty ||
        recipients.contains(currentEmail)) {
      // Notification is for this user, add it to the list and notify listeners
      await fetchNotifications();

      // Show a local notification
      _showLocalNotification(
        NotificationModel.fromJson(notificationData),
      );
    }
  }

  Future<void> fetchNotifications() async {
    try {
      // Get current user's email
      final currentEmail = await _storage.read(key: 'user_email');
      if (currentEmail == null) return;

      // Get notifications from Supabase where:
      // - recipients is null (for all users) OR
      // - current user's email is in the recipients list
      final data = await _supabaseClient
          .from('notifications')
          .select()
          .or('recipients.is.null,recipients.cs.{${currentEmail}}')
          .order('created_at', ascending: false);

      final notifications = (data as List)
          .map((json) =>
              NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update the stream with new notifications
      _notificationsStreamController.add(notifications);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      // Add empty list in case of error
      _notificationsStreamController.add([]);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseClient
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);

      // Refresh notifications
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  void _showLocalNotification(NotificationModel notification) {
    // In a real app, you would use a notification package like flutter_local_notifications
    // or firebase_messaging to show a local notification to the user
    // This is a placeholder for that functionality
    debugPrint(
        'New notification: ${notification.title} - ${notification.message}');
  }

  void _subscribeToBloodRequests() {
    _channel = _supabaseClient
        .channel('blood_requests_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'blood_requests',
          callback: (payload) {
            _handleNewBloodRequest(payload.newRecord);
          },
        )
        .subscribe();

    debugPrint('Subscribed to blood_requests table');
  }

  void _handleNewBloodRequest(Map<String, dynamic> record) {
    try {
      // Convert the record to a BloodRequest object
      final BloodRequest request = BloodRequest.fromJson(record);

      // Check if this notification should be shown to the current user
      // This is a simple implementation - you might want to add user filtering logic here
      // based on the recipients field

      // Show a local notification
      _showBloodRequestNotification(request);

      debugPrint('New blood request received: ${request.patientName}');
    } catch (e) {
      debugPrint('Error handling blood request: $e');
    }
  }

  Future<void> _showBloodRequestNotification(BloodRequest request) async {
    // Create notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'blood_requests_channel',
      'Blood Donation Requests',
      channelDescription: 'Notifications for blood donation requests',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Create title and body based on blood request
    final String title = 'URGENT: ${request.bloodType} Blood Needed';
    final String body =
        '${request.patientName} at ${request.hospital} - ${request.urgency} priority';

    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      request.id.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: request.id,
    );
  }

  Future<List<BloodRequest>> getBloodRequests() async {
    try {
      final response = await _supabaseClient
          .from('blood_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((record) => BloodRequest.fromJson(record))
          .toList();
    } catch (e) {
      debugPrint('Error fetching blood requests: $e');
      return [];
    }
  }

  void dispose() {
    _notificationsStreamController.close();
    _channel?.unsubscribe();
  }

  static const String baseUrl = 'https://api.blooddonationapp.com';

  // Simulate fetching blood requests with mock data
  Future<List<BloodRequest>> getBloodRequestsMock() async {
    // In a real app, this would be an API call
    // return http.get(Uri.parse('$baseUrl/blood-requests'))
    //    .then((response) {
    //      if (response.statusCode == 200) {
    //        final List<dynamic> data = json.decode(response.body);
    //        return data.map((json) => BloodRequest.fromJson(json)).toList();
    //      } else {
    //        throw Exception('Failed to load blood requests');
    //      }
    //    });

    // For demo purposes, we'll use mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return _getMockBloodRequests();
  }

  // Create a new blood request
  Future<BloodRequest> createBloodRequest(BloodRequest request) async {
    // In a real app, this would be an API call
    // return http.post(
    //   Uri.parse('$baseUrl/blood-requests'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(request.toJson()),
    // ).then((response) {
    //   if (response.statusCode == 201) {
    //     return BloodRequest.fromJson(json.decode(response.body));
    //   } else {
    //     throw Exception('Failed to create blood request');
    //   }
    // });

    // For demo purposes, we'll just return the request with a generated ID
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    return BloodRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bloodType: request.bloodType,
      patientName: request.patientName,
      hospital: request.hospital,
      urgency: request.urgency,
      createdAt: DateTime.now(),
      contactPhone: request.contactPhone,
      unitsNeeded: request.unitsNeeded,
      notes: request.notes,
    );
  }

  // Mock data for demo purposes
  List<BloodRequest> _getMockBloodRequests() {
    return [
      BloodRequest(
        id: '1',
        bloodType: 'O+',
        patientName: 'John Doe',
        hospital: 'General Hospital',
        urgency: 'critical',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        contactPhone: '+1 (555) 123-4567',
        unitsNeeded: 3,
        notes: 'Accident victim needs immediate transfusion',
      ),
      BloodRequest(
        id: '2',
        bloodType: 'A-',
        patientName: 'Sarah Johnson',
        hospital: 'Memorial Medical Center',
        urgency: 'urgent',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        contactPhone: '+1 (555) 987-6543',
        unitsNeeded: 2,
        notes: 'Scheduled surgery tomorrow morning',
      ),
      BloodRequest(
        id: '3',
        bloodType: 'B+',
        patientName: 'Michael Smith',
        hospital: 'City Hospital',
        urgency: 'standard',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        contactPhone: '+1 (555) 456-7890',
        unitsNeeded: 1,
      ),
      BloodRequest(
        id: '4',
        bloodType: 'AB+',
        patientName: 'Emily Davis',
        hospital: 'University Medical Center',
        urgency: 'critical',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        contactPhone: '+1 (555) 234-5678',
        unitsNeeded: 2,
        notes: 'Transplant patient needs blood urgently',
      ),
    ];
  }
}
