import 'package:flutter/material.dart';

class Lesson {
  final String title;
  final String level;
  final IconData icon;
  final MaterialColor color;
  final String contentPath; // Ders içeriği dosyasına giden yol

  const Lesson({
    required this.title,
    required this.level,
    required this.icon,
    required this.color,
    required this.contentPath,
  });
}