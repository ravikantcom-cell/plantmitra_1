// lib/utils/logger.dart
import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = 'PlantMitra';
  
  static void debug(String message) {
    if (kDebugMode) {
      print('[$_tag][DEBUG] $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      print('[$_tag][INFO] $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      print('[$_tag][WARNING] $message');
    }
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[$_tag][ERROR] $message');
      if (error != null) {
        print('[$_tag][ERROR] Details: $error');
      }
      if (stackTrace != null) {
        print('[$_tag][ERROR] Stack trace: $stackTrace');
      }
    }
  }
}