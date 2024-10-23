import 'dart:convert';
import 'package:flutter/material.dart';

class Reminder {
  String eventName;
  DateTime date;
  bool repeat;
  String? notes;
  TimeOfDay? alarmTime;
  String? imagePath;
  double opacity;
  int? notificationId;

  Reminder({
    required this.eventName,
    required this.date,
    required this.repeat,
    this.notes,
    this.alarmTime,
    this.imagePath,
    this.opacity = 1.0,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'date': date.toIso8601String(),
      'repeat': repeat,
      'notes': notes,
      'alarmTime': alarmTime != null
          ? {'hour': alarmTime!.hour, 'minute': alarmTime!.minute}
          : null,
      'imagePath': imagePath,
      'opacity': opacity,
      'notificationId': notificationId,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      eventName: map['eventName'],
      date: DateTime.parse(map['date']),
      repeat: map['repeat'],
      notes: map['notes'],
      alarmTime: map['alarmTime'] != null
          ? TimeOfDay(hour: map['alarmTime']['hour'], minute: map['alarmTime']['minute'])
          : null,
      imagePath: map['imagePath'],
      opacity: map['opacity'] ?? 1.0,
      notificationId: map['notificationId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Reminder.fromJson(String source) =>
      Reminder.fromMap(json.decode(source));
}
