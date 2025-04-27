class NotificationModel {
  final String id;
  final String title;
  final String message;
  final List<String>? recipients;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.recipients,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      recipients: json['recipients'] != null
          ? List<String>.from(json['recipients'])
          : null,
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'recipients': recipients,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
