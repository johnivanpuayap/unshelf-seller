import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String text;
  final DateTime? createdAt;
  bool seen;

  NotificationModel({
    required this.id,
    required this.title,
    required this.text,
    this.createdAt,
    this.seen = false,
  });

  factory NotificationModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    final raw = data['created_at'];
    DateTime? created;
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is DateTime) {
      created = raw;
    }
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      text: data['message'] ?? '',
      createdAt: created,
      seen: data['seen'] ?? false,
    );
  }
}
