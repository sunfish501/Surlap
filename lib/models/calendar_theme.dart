import 'dart:convert';
import 'package:flutter/material.dart';

class CalendarTheme {
  final String id;
  final String name;
  final String color;   // hex '#rrggbb'
  final String? image;
  final String? shareCode;
  final String? shareRole; // 'owner' | 'subscriber'

  const CalendarTheme({
    required this.id,
    required this.name,
    required this.color,
    this.image,
    this.shareCode,
    this.shareRole,
  });

  Color get colorValue {
    try {
      final hex = color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    if (image != null) 'image': image,
    if (shareCode != null) 'share_code': shareCode,
    if (shareRole != null) 'share_role': shareRole,
  };

  factory CalendarTheme.fromJson(Map<String, dynamic> j) => CalendarTheme(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    color: (j['color'] ?? '#888888').toString(),
    image: j['image'] as String?,
    shareCode: j['share_code'] as String?,
    shareRole: j['share_role'] as String?,
  );

  CalendarTheme copyWith({
    String? id, String? name, String? color,
    String? image, String? shareCode, String? shareRole,
  }) => CalendarTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    image: image ?? this.image,
    shareCode: shareCode ?? this.shareCode,
    shareRole: shareRole ?? this.shareRole,
  );

  static List<CalendarTheme> listFromJson(String raw) {
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CalendarTheme.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<CalendarTheme> themes) =>
      jsonEncode(themes.map((t) => t.toJson()).toList());
}
