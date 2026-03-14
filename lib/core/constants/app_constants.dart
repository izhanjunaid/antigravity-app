import 'package:flutter/material.dart';

class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://emeqrvtwgyshxewzrfeh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtZXFydnR3Z3lzaHhld3pyZmVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTU3MTYsImV4cCI6MjA4ODc5MTcxNn0.c8kjIqLmlsV1oFdGVj7-OCrTulF0zCyrJlQ_VCGNPPc';

  // Colors
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF1A1F36);
  static const Color surfaceLight = Color(0xFF242942);
  static const Color primary = Color(0xFF2979FF);
  static const Color primaryLight = Color(0xFF448AFF);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color error = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E99A4);
  static const Color cardBorder = Color(0xFF2A2F45);

  // Dimensions
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;
  static const double pagePadding = 20.0;

  // User Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';
  static const String roleSectionHead = 'section_head';
  static const String rolePrincipal = 'principal';
}
